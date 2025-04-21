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
    final seedColor = Colors.deepPurple;
    return MaterialApp(
      title: 'Rive File Viewer',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ).surfaceContainerHighest, // Slightly different AppBar background
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        )),
        sliderTheme: SliderThemeData(
          showValueIndicator:
              ShowValueIndicator.always, // Keep indicator visible
        ),
      ),
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fileName = null;
      _fileBytes = null;
      _riveFile = null;
      _artboard = null;
      _resetControllersAndSelection();
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['riv'],
        withData: true,
      );

      if (result?.files.single.bytes != null) {
        if (!mounted) return;
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
          _errorMessage = "Error picking file: ${e.toString()}";
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

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _riveFile = RiveFile.import(ByteData.view(_fileBytes!.buffer));
      _artboard = _riveFile?.mainArtboard.instance();

      if (_artboard == null) {
        throw Exception("Could not load main artboard.");
      }

      _resetControllersAndSelection();

      if (_artboard!.stateMachines.isNotEmpty) {
        _selectedStateMachineName = _artboard!.stateMachines.first.name;
        _initStateMachineController();
      } else if (_artboard!.animations.isNotEmpty) {
        _selectedAnimationName = _artboard!.animations.first.name;
        _initSimpleAnimationController();
      } else {
        _resetControllersAndSelection(); // Ensure clean state if no controllers
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Rive file loading error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading Rive: ${e.toString()}";
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
      print("Error creating SM Controller: $e");
      _errorMessage =
          "Init SM '$_selectedStateMachineName' Error: ${e.toString()}";
    }

    if (controller != null) {
      _artboard!.addController(controller);
      _stateMachineController = controller;
      _inputs.addAll(controller.inputs);
    } else {
      _stateMachineController = null;
      if (_errorMessage == null) {
        _errorMessage = "Could not init SM: '$_selectedStateMachineName'";
      }
    }
    if (mounted) setState(() {});
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
      print("Error creating SimpleAnim controller: $e");
      _simpleAnimationController = null;
      _errorMessage =
          "Init Anim '$_selectedAnimationName' Error: ${e.toString()}";
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    _simpleAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive File Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Pick Rive File',
            onPressed: _isLoading ? null : _pickFile,
            iconSize: 28,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: colorScheme.onErrorContainer, size: 44),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: colorScheme.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colorScheme.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )),
      );
    }
    if (_artboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_outlined,
                size: 60, color: colorScheme.primary),
            const SizedBox(height: 20),
            const Text('Pick a .riv file to begin'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Pick File'),
              onPressed: _pickFile,
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3, // Give Rive view slightly more space
          child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainer,
              ),
              clipBehavior:
                  Clip.antiAlias, // Ensures Rive respects rounded corners
              child: Rive(
                artboard: _artboard!,
                fit: BoxFit.contain,
              )),
        ),
        Expanded(
          flex: 2, // Controls panel space
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Make cards fill width
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('File Info',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_fileName != null)
                          Text(
                            _fileName!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Artboard: ${_artboard?.name ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildStateMachineSelector(context),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildAnimationSelector(context),
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedStateMachineName != null &&
                    _stateMachineController != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inputs for "$_selectedStateMachineName"',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_inputs.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No inputs found.',
                                  style: Theme.of(context).textTheme.bodySmall),
                            )
                          else
                            ..._inputs
                                .map((input) => _buildInputControl(input))
                                .toList(),
                        ],
                      ),
                    ),
                  )
                else if (_selectedAnimationName != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Playing Animation:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('$_selectedAnimationName',
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          if (_simpleAnimationController != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                icon: Icon(_simpleAnimationController!.isActive
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline),
                                label: Text(_simpleAnimationController!.isActive
                                    ? 'Pause'
                                    : 'Play'),
                                onPressed: () {
                                  if (mounted &&
                                      _simpleAnimationController != null) {
                                    setState(() => _simpleAnimationController!
                                            .isActive =
                                        !_simpleAnimationController!.isActive);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateMachineSelector(BuildContext context) {
    final allStateMachineNames =
        _artboard?.stateMachines.map((sm) => sm.name).toList() ?? [];
    final uniqueStateMachineNames = allStateMachineNames.toSet().toList();

    if (uniqueStateMachineNames.isEmpty) {
      return Text('No State Machines found.',
          style: Theme.of(context).textTheme.bodySmall);
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
        Text('State Machines', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: isSelectedValueDuplicatedSM ? null : _selectedStateMachineName,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText:
                isSelectedValueDuplicatedSM && _selectedStateMachineName != null
                    ? '(Duplicate: $_selectedStateMachineName)'
                    : '(Select to activate)',
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.7)),
          ),
          items: uniqueStateMachineNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name, overflow: TextOverflow.ellipsis),
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

  Widget _buildAnimationSelector(BuildContext context) {
    final allAnimationNames =
        _artboard?.animations.map((anim) => anim.name).toList() ?? [];
    final uniqueAnimationNames = allAnimationNames.toSet().toList();

    if (uniqueAnimationNames.isEmpty) {
      return Text('No Simple Animations found.',
          style: Theme.of(context).textTheme.bodySmall);
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
        Text('Simple Animations',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: isSelectedValueDuplicated ? null : _selectedAnimationName,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText:
                isSelectedValueDuplicated && _selectedAnimationName != null
                    ? '(Duplicate: $_selectedAnimationName)'
                    : '(Select to activate)',
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.7)),
          ),
          items: uniqueAnimationNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name, overflow: TextOverflow.ellipsis),
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
        ExpansionTile(
          title: Text('Full List (${allAnimationNames.length})',
              style: Theme.of(context).textTheme.labelSmall),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: allAnimationNames.isEmpty
              ? [Text('None', style: Theme.of(context).textTheme.bodySmall)]
              : allAnimationNames
                  .map((name) => Text("- $name",
                      style: Theme.of(context).textTheme.bodySmall))
                  .toList(),
        )
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
      return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('Unknown input type: ${input.name}',
              style: Theme.of(context).textTheme.bodySmall));
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${input.name}: ${input.value.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium),
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
    return ListTile(
      title: Text(input.name, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Switch(
        value: input.value,
        onChanged: (bool value) {
          if (mounted) {
            setState(() {
              input.value = value;
            });
          }
        },
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTriggerInput(SMITrigger input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FilledButton.icon(
        icon: const Icon(Icons.bolt_outlined, size: 18),
        label: Text('Fire: ${input.name}'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact, // Make button slightly smaller
          // backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          // foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
        onPressed: () {
          try {
            input.fire();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Triggered: ${input.name}'),
                  duration: const Duration(milliseconds: 800),
                  behavior: SnackBarBehavior.floating, // More modern look
                ),
              );
            }
          } catch (e) {
            print("Error firing trigger ${input.name}: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error firing ${input.name}: ${e.toString()}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
