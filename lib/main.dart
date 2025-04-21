import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rive/rive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await RiveFile.initialize();
  } catch (e) {
    print("Failed to initialize Rive: $e");
  }
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
  SimpleAnimation? _simpleAnimationController;
  String? _selectedStateMachineName;
  String? _selectedAnimationName;
  final List<SMIInput> _inputs = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fileName = null;
      _fileBytes = null;
      _riveFile = null;
      _artboard = null;
      _stateMachineController?.dispose();
      _simpleAnimationController?.dispose();
      _stateMachineController = null;
      _simpleAnimationController = null;
      _selectedStateMachineName = null;
      _selectedAnimationName = null;
      _inputs.clear();
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['riv'],
        withData: true,
      );

      if (result?.files.single.bytes != null) {
        _fileName = result!.files.single.name;
        _fileBytes = result.files.single.bytes!;
        _loadRiveFile();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("File picking/reading error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error picking or reading file: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _loadRiveFile() {
    if (_fileBytes == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "File data is missing.";
          _isLoading = false;
        });
      }
      return;
    }
    ;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _riveFile = RiveFile.import(ByteData.view(_fileBytes!.buffer));
      _artboard = _riveFile?.mainArtboard.instance();

      if (_artboard == null) {
        throw Exception("Could not load the main artboard from the Rive file.");
      }

      _resetControllersAndSelection();

      if (_artboard!.stateMachines.isNotEmpty) {
        _selectedStateMachineName = _artboard!.stateMachines.first.name;
        _initStateMachineController();
      } else if (_artboard!.animations.isNotEmpty) {
        _selectedAnimationName = _artboard!.animations.first.name;
        _initSimpleAnimationController();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Rive file loading error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading Rive file: ${e.toString()}";
          _riveFile = null;
          _artboard = null;
          _isLoading = false;
        });
      }
    }
  }

  void _resetControllersAndSelection() {
    _stateMachineController?.dispose();
    _simpleAnimationController?.dispose();
    _stateMachineController = null;
    _simpleAnimationController = null;
    _inputs.clear();
    _selectedStateMachineName = null;
    _selectedAnimationName = null;
  }

  void _initStateMachineController() {
    if (!mounted || _artboard == null || _selectedStateMachineName == null)
      return;

    _simpleAnimationController?.dispose();
    _simpleAnimationController = null;
    _stateMachineController?.dispose();
    _inputs.clear();

    StateMachineController? controller;
    try {
      controller = StateMachineController.fromArtboard(
        _artboard!,
        _selectedStateMachineName!,
        onStateChange: (stateMachineName, stateName) {
          print('State Changed: $stateMachineName -> $stateName');
        },
      );
    } catch (e) {
      print("Error creating StateMachineController: $e");
      _errorMessage =
          "Error creating controller for '$_selectedStateMachineName': ${e.toString()}";
    }

    if (controller != null) {
      _artboard!.addController(controller);
      _stateMachineController = controller;
      _inputs.addAll(controller.inputs);
    } else {
      _stateMachineController = null;
      if (_errorMessage == null) {
        _errorMessage =
            "Could not initialize State Machine: '$_selectedStateMachineName'";
      }
    }

    setState(() {});
  }

  void _initSimpleAnimationController() {
    if (!mounted || _artboard == null || _selectedAnimationName == null) return;

    _stateMachineController?.dispose();
    _stateMachineController = null;
    _inputs.clear();
    _simpleAnimationController?.dispose();

    SimpleAnimation? controller;
    try {
      controller = SimpleAnimation(
        _selectedAnimationName!,
        autoplay: true,
      );
      _artboard!.addController(controller);
      _simpleAnimationController = controller;
    } catch (e) {
      print("Error creating SimpleAnimation controller: $e");
      _simpleAnimationController = null;
      _errorMessage =
          "Error creating animation controller for '$_selectedAnimationName': ${e.toString()}";
    }

    setState(() {});
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    _simpleAnimationController?.dispose();
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
            onPressed: _isLoading ? null : _pickFile,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.error, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Error:',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            )),
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
              child: Rive(
                artboard: _artboard!,
                fit: BoxFit.contain,
              )),
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
                const SizedBox(height: 16),
                _buildAnimationSelector(),
                const Divider(height: 24),
                if (_selectedStateMachineName != null &&
                    _stateMachineController != null) ...[
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
                ] else if (_selectedAnimationName != null) ...[
                  Text(
                    'Playing Animation:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('$_selectedAnimationName'),
                  const SizedBox(height: 8),
                  if (_simpleAnimationController != null)
                    ElevatedButton.icon(
                        icon: Icon(_simpleAnimationController!.isActive
                            ? Icons.pause
                            : Icons.play_arrow),
                        label: Text(_simpleAnimationController!.isActive
                            ? 'Pause'
                            : 'Play'),
                        onPressed: () {
                          if (mounted && _simpleAnimationController != null) {
                            setState(() =>
                                _simpleAnimationController!.isActive =
                                    !_simpleAnimationController!.isActive);
                          }
                        }),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateMachineSelector() {
    final allStateMachineNames =
        _artboard?.stateMachines.map((sm) => sm.name).toList() ?? [];
    final uniqueStateMachineNames = allStateMachineNames.toSet().toList();

    if (uniqueStateMachineNames.isEmpty) {
      return const Text('No State Machines found.');
    }

    bool isSelectedValueDuplicatedSM = false;
    if (_selectedStateMachineName != null) {
      final count = allStateMachineNames
          .where((name) => name == _selectedStateMachineName)
          .length;
      isSelectedValueDuplicatedSM = count > 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select State Machine:',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: isSelectedValueDuplicatedSM ? null : _selectedStateMachineName,
          isExpanded: true,
          hint: Text(
              isSelectedValueDuplicatedSM && _selectedStateMachineName != null
                  ? '(Duplicate: $_selectedStateMachineName)'
                  : '(Select to activate)'),
          items: uniqueStateMachineNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedStateMachineName) {
              if (mounted) {
                setState(() {
                  _selectedAnimationName = null;
                  _selectedStateMachineName = newValue;
                  _initStateMachineController();
                });
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildAnimationSelector() {
    final allAnimationNames =
        _artboard?.animations.map((anim) => anim.name).toList() ?? [];
    final uniqueAnimationNames = allAnimationNames.toSet().toList();

    if (uniqueAnimationNames.isEmpty) {
      return const Text('No Simple Animations found.');
    }

    bool isSelectedValueDuplicated = false;
    if (_selectedAnimationName != null) {
      final count = allAnimationNames
          .where((name) => name == _selectedAnimationName)
          .length;
      isSelectedValueDuplicated = count > 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Simple Animation:',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: isSelectedValueDuplicated ? null : _selectedAnimationName,
          isExpanded: true,
          hint: Text(isSelectedValueDuplicated && _selectedAnimationName != null
              ? '(Duplicate: $_selectedAnimationName)'
              : '(Select to activate)'),
          items: uniqueAnimationNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedAnimationName) {
              if (mounted) {
                setState(() {
                  _selectedStateMachineName = null;
                  _selectedAnimationName = newValue;
                  _initSimpleAnimationController();
                });
              }
            }
          },
        ),
        const SizedBox(height: 10),
        Text('Animations List (${allAnimationNames.length}):',
            style: Theme.of(context).textTheme.labelSmall),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: allAnimationNames
              .map((name) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Text("- $name"),
                  ))
              .toList(),
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
      maxVal = input.value * 1.5;
    } else if (input.value < 0.0) {
      minVal = input.value * 1.5;
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
              if (mounted) {
                setState(() {
                  input.value = value;
                });
              }
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
              if (mounted) {
                setState(() {
                  input.value = value;
                });
              }
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
          try {
            input.fire();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Triggered: ${input.name}'),
                    duration: const Duration(seconds: 1)),
              );
            }
          } catch (e) {
            print("Error firing trigger ${input.name}: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Error firing ${input.name}: ${e.toString()}'),
                    duration: const Duration(seconds: 2)),
              );
            }
          }
        },
        child: Text('Fire: ${input.name} (Trigger)'),
      ),
    );
  }
}
