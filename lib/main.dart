import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For picking files
import 'package:rive/rive.dart'; // The core Rive package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveFile.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive File Viewer (Windows)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const RiveViewerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RiveViewerPage extends StatefulWidget {
  const RiveViewerPage({super.key});

  @override
  State<RiveViewerPage> createState() => _RiveViewerPageState();
}

class _RiveViewerPageState extends State<RiveViewerPage> {
  String? _fileName;
  Uint8List? _fileBytes;
  RiveFile? _riveFile;
  Artboard? _artboard;
  StateMachineController? _stateMachineController;
  String? _selectedStateMachineName;
  final List<SMIInput> _inputs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // --- File Picking ---
  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Reset previous state
      _fileName = null;
      _fileBytes = null;
      _riveFile = null;
      _artboard = null;
      _stateMachineController?.dispose();
      _stateMachineController = null;
      _selectedStateMachineName = null;
      _inputs.clear();
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['riv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        _fileName = result.files.single.name;
        _fileBytes = result.files.single.bytes!;
        _loadRiveFile();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("File picking/reading error: $e");
      setState(() {
        _errorMessage = "Error picking or reading file: $e";
        _isLoading = false;
      });
    }
  }

  void _loadRiveFile() {
    if (_fileBytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _riveFile = RiveFile.import(ByteData.view(_fileBytes!.buffer));

      _artboard = _riveFile?.mainArtboard.instance(); // Create an instance

      if (_artboard == null) {
        throw Exception("Could not load the main artboard from the Rive file.");
      }

      if (_artboard!.stateMachines.isNotEmpty) {
        _selectedStateMachineName = _artboard!.stateMachines.first.name;
        _initStateMachineController(); // Initialize controller for the first SM
      } else {
        _stateMachineController?.dispose();
        _stateMachineController = null;
        _inputs.clear();
        _selectedStateMachineName = null;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("Rive file loading error: $e");
      setState(() {
        _errorMessage = "Error loading Rive file: $e";
        _riveFile = null;
        _artboard = null;
        _isLoading = false;
      });
    }
  }

  void _initStateMachineController() {
    if (_artboard == null || _selectedStateMachineName == null) return;

    _stateMachineController?.dispose();
    _inputs.clear();

    var controller = StateMachineController.fromArtboard(
      _artboard!,
      _selectedStateMachineName!,
      onStateChange: (stateMachineName, stateName) {
        print('State Changed: $stateMachineName -> $stateName');
      },
    );

    if (controller != null) {
      _artboard!.addController(controller);
      _stateMachineController = controller;
      _inputs.addAll(controller.inputs);
    } else {
      _stateMachineController = null;
      _errorMessage =
          "Could not find or initialize State Machine: '$_selectedStateMachineName'";
    }

    setState(() {});
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive File Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Pick Rive File',
            onPressed: _pickFile,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_errorMessage',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_artboard == null) {
      return const Center(
        child: Text('Pick a .riv file using the folder icon above.'),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: _artboard != null
                ? Rive(
                    artboard: _artboard!,
                    fit: BoxFit.contain,
                  )
                : const Center(child: Text("Artboard could not be loaded.")),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_fileName != null)
                  Text(
                    _fileName!,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Text(
                  'Artboard: ${_artboard?.name ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Divider(height: 24),
                _buildStateMachineSelector(),
                const Divider(height: 24),
                if (_stateMachineController != null) ...[
                  Text(
                    'Inputs for "$_selectedStateMachineName":',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_inputs.isEmpty)
                    const Text('No inputs found for this state machine.')
                  else
                    ..._inputs
                        .map((input) => _buildInputControl(input))
                        .toList(),
                ] else if (_selectedStateMachineName != null) ...[
                  Text(
                    'Inputs for "$_selectedStateMachineName":',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'State machine selected, but no controller active or no inputs found.'),
                ],
                const SizedBox(height: 20),
                _buildOtherInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateMachineSelector() {
    final stateMachineNames =
        _artboard?.stateMachines.map((sm) => sm.name).toList() ?? [];

    if (stateMachineNames.isEmpty) {
      return const Text('No State Machines found in this Artboard.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select State Machine:',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _selectedStateMachineName,
          isExpanded: true,
          hint: const Text('Select a State Machine'),
          items: stateMachineNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedStateMachineName) {
              setState(() {
                _selectedStateMachineName = newValue;

                _initStateMachineController();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildInputControl(SMIInput input) {
    if (input is SMINumber) {
      return _buildNumberInput(input);
    } else if (input is SMIBool) {
      return _buildBooleanInput(input);
    } else if (input is SMITrigger) {
      return _buildTriggerInput(input);
    } else {
      return ListTile(title: Text('Unknown input type: ${input.name}'));
    }
  }

  Widget _buildNumberInput(SMINumber input) {
    double minVal = 0.0;
    double maxVal = 100.0;
    if (input.value > 1.0 && input.value <= 100.0) {
      minVal = 0.0;
      maxVal = 100.0;
    } else if (input.value > 100.0) {
      minVal = 0.0;
      maxVal = input.value * 2;
    } else if (input.value < 0.0) {
      minVal = input.value * 2;
      maxVal = 0.0;
    }
    final currentVal = input.value.clamp(minVal, maxVal);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${input.name} (Number): ${input.value.toStringAsFixed(2)}'),
          Slider(
            value: currentVal,
            min: minVal,
            max: maxVal,
            divisions: 100,
            label: input.value.toStringAsFixed(2),
            onChanged: (double value) {
              setState(() {
                input.value = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanInput(SMIBool input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${input.name} (Boolean):'),
          Switch(
            value: input.value,
            onChanged: (bool value) {
              setState(() {
                input.value = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerInput(SMITrigger input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          input.fire();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Triggered: ${input.name}'),
                duration: const Duration(seconds: 1)),
          );
        },
        child: Text('Fire: ${input.name} (Trigger)'),
      ),
    );
  }

  Widget _buildOtherInfo() {
    final animationNames =
        _artboard?.animations.map((anim) => anim.name).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text('Other Information:',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Animations (${animationNames.length}):'),
        if (animationNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: Text(animationNames.join(', ')),
          )
        else
          const Padding(
            padding: EdgeInsets.only(left: 8.0, top: 4.0),
            child: Text('No simple animations found.'),
          ),
      ],
    );
  }
}
