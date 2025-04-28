import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rive/rive.dart';

class RiveController extends ChangeNotifier {
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

  // State for number input ranges
  final Map<String, RangeValues> _numberInputRanges = {};
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _maxControllers = {};

  // Getters
  String? get fileName => _fileName;
  RiveFile? get riveFile => _riveFile;
  Artboard? get artboard => _artboard;
  StateMachineController? get stateMachineController => _stateMachineController;
  SimpleAnimation? get simpleAnimationController => _simpleAnimationController;
  String? get selectedStateMachineName => _selectedStateMachineName;
  String? get selectedAnimationName => _selectedAnimationName;
  List<SMIInput> get inputs => List.unmodifiable(_inputs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, RangeValues> get numberInputRanges => _numberInputRanges;
  Map<String, TextEditingController> get minControllers => _minControllers;
  Map<String, TextEditingController> get maxControllers => _maxControllers;

  bool get isFileLoaded =>
      _fileBytes != null && _riveFile != null && _artboard != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    _isLoading = false;
    _resetRiveState(
        clearFileData: message != null &&
            _fileBytes == null); // Clear only if file itself failed
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners(); // Notify if error was cleared
    }
  }

  Future<void> pickFile() async {
    _setLoading(true);
    clearError();
    _resetRiveState(clearFileData: true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['riv'],
        withData: true,
      );

      if (result?.files.single.bytes != null) {
        _fileName = result!.files.single.name;
        _fileBytes = result.files.single.bytes!;
        _loadRiveFile(); // Will handle setting loading to false
      } else {
        _setLoading(false); // No file picked or data missing
      }
    } catch (e) {
      debugPrint("File picking/reading error: $e");
      _setError("Error picking file: ${e.toString()}");
    }
  }

  void _loadRiveFile({bool isReload = false}) {
    if (_fileBytes == null) {
      if (!isReload) _setError("File data is missing.");
      return;
    }

    _setLoading(true);
    clearError();

    try {
      // Import the Rive file from bytes
      _riveFile = RiveFile.import(ByteData.view(_fileBytes!.buffer));
      // Get the main artboard instance
      _artboard = _riveFile?.mainArtboard.instance();

      if (_artboard == null) {
        throw Exception("Could not load main artboard.");
      }

      // Reset controllers and selections before initializing new ones
      _resetControllersAndSelection();

      // Prioritize setting StateMachine if available, else SimpleAnimation
      if (_artboard!.stateMachines.isNotEmpty) {
        // Select the first unique state machine name
        _selectedStateMachineName =
            _artboard!.stateMachines.map((sm) => sm.name).toSet().first;
        _initStateMachineController();
      } else if (_artboard!.animations.isNotEmpty) {
        // Select the first unique animation name
        _selectedAnimationName =
            _artboard!.animations.map((a) => a.name).toSet().first;
        _initSimpleAnimationController();
      } else {
        // No controllers to initialize if artboard has neither
        _resetControllersAndSelection();
      }

      _setLoading(false);
    } catch (e) {
      debugPrint("Rive file loading error: $e");
      _setError("Error loading Rive file '$_fileName': ${e.toString()}");
      _resetRiveState(
          clearFileData: !isReload); // Keep file data on reload error
    }
  }

  // Method to reload the current file
  void reloadRiveFile() {
    if (_fileBytes == null) {
      _setError("No file loaded to reload.");
      return;
    }
    debugPrint("Reloading Rive file...");
    _loadRiveFile(isReload: true);
  }

  void _resetRiveState({bool clearFileData = false}) {
    _resetControllersAndSelection();
    _artboard = null; // Dispose/clear instance
    _riveFile = null; // Clear parsed file
    _numberInputRanges.clear();
    _minControllers.forEach((_, ctrl) => ctrl.dispose());
    _maxControllers.forEach((_, ctrl) => ctrl.dispose());
    _minControllers.clear();
    _maxControllers.clear();

    if (clearFileData) {
      _fileName = null;
      _fileBytes = null;
    }
    // Don't notify here, callers (_setError, pickFile, loadRiveFile) will notify
  }

  void _resetControllersAndSelection() {
    // Dispose existing controllers to prevent memory leaks
    _stateMachineController?.dispose();
    _simpleAnimationController?.dispose();

    _stateMachineController = null;
    _simpleAnimationController = null;
    _inputs.clear();
    _selectedStateMachineName = null;
    _selectedAnimationName = null;
    // Keep _numberInputRanges, _minControllers, _maxControllers unless full reset
    // No need to notify here, callers will handle it
  }

  void selectStateMachine(String name) {
    if (_riveFile == null ||
        _artboard == null ||
        name == _selectedStateMachineName) return;

    _selectedStateMachineName = name;
    _selectedAnimationName = null; // Deselect animation
    _initStateMachineController();
    notifyListeners();
  }

  void selectAnimation(String name) {
    if (_riveFile == null ||
        _artboard == null ||
        name == _selectedAnimationName) return;

    _selectedAnimationName = name;
    _selectedStateMachineName = null; // Deselect state machine
    _initSimpleAnimationController();
    notifyListeners();
  }

  void _initStateMachineController() {
    if (_artboard == null || _selectedStateMachineName == null) return;

    _simpleAnimationController?.dispose(); // Dispose animation if switching
    _simpleAnimationController = null;
    _stateMachineController?.dispose(); // Dispose previous SM
    _inputs.clear();
    _numberInputRanges.clear(); // Clear ranges for new SM
    _minControllers.forEach((_, ctrl) => ctrl.dispose());
    _maxControllers.forEach((_, ctrl) => ctrl.dispose());
    _minControllers.clear();
    _maxControllers.clear();

    // It's often safer to get a fresh instance when changing controllers majorly
    _artboard = _riveFile!.mainArtboard.instance();
    if (_artboard == null) {
      debugPrint("Error: Could not get a fresh artboard instance for SM.");
      _setError("Failed to re-initialize artboard for State Machine.");
      return;
    }

    StateMachineController? controller;
    try {
      controller = StateMachineController.fromArtboard(
        _artboard!,
        _selectedStateMachineName!,
        onStateChange: _onStateChange,
      );
    } catch (e) {
      debugPrint(
          "Error creating SM Controller for '$_selectedStateMachineName': $e");
      _setError("Init SM '$_selectedStateMachineName' Error: ${e.toString()}");
    }

    if (controller != null) {
      _artboard!.addController(controller);
      _stateMachineController = controller;
      _inputs.addAll(controller.inputs);
      _initializeInputRangesAndControllers(); // Setup ranges for number inputs
    } else {
      _stateMachineController = null;
      // Error message might already be set by the catch block
      if (_errorMessage == null) {
        _setError(
            "Could not initialize State Machine: '$_selectedStateMachineName'");
      }
    }
    // Notify handled by selectStateMachine or _setError
  }

  void _initSimpleAnimationController() {
    if (_artboard == null || _selectedAnimationName == null) return;

    // --- Dispose existing controllers ---
    _stateMachineController?.dispose();
    _stateMachineController = null;
    _inputs.clear();
    // Clear number range state when switching away from state machines
    _numberInputRanges.clear();
    _minControllers.forEach((_, ctrl) => ctrl.dispose());
    _maxControllers.forEach((_, ctrl) => ctrl.dispose());
    _minControllers.clear();
    _maxControllers.clear();
    _simpleAnimationController?.dispose(); // Dispose previous animation

    // --- Re-initialize artboard instance ---
    // It's often necessary to get a fresh instance when changing animation controllers
    // to ensure the new controller applies correctly without interference.
    _artboard = _riveFile!.mainArtboard.instance();
    if (_artboard == null) {
      debugPrint(
          "Error: Could not get a fresh artboard instance for Animation.");
      _setError("Failed to re-initialize artboard for Animation.");
      return;
    }

    // --- Create and add the new animation controller ---
    SimpleAnimation? controller;
    try {
      controller = SimpleAnimation(
        _selectedAnimationName!,
        autoplay: true, // Keep autoplay true for default behavior
      );
      _artboard!.addController(controller);

      // --- ADD THIS LINE ---
      // Explicitly set the controller to active to ensure it starts playing
      // and the UI reflects the correct initial state immediately.
      controller.isActive = true;
      // --- END OF ADDED LINE ---

      _simpleAnimationController = controller; // Assign the new controller
      clearError(); // Clear any previous error on success
    } catch (e) {
      debugPrint(
          "Error creating SimpleAnim controller '$_selectedAnimationName': $e");
      _simpleAnimationController = null;
      _setError("Init Anim '$_selectedAnimationName' Error: ${e.toString()}");
    }
    // The calling method (selectAnimation) handles notifyListeners()
  }

  void _onStateChange(String machineName, String stateName) {
    debugPrint('State Change [$machineName]: $stateName');
    // Could add more logic here if needed based on state changes
    // Be careful with notifyListeners() here, could cause rapid updates
  }

  // ----- Input Handling -----

  void _initializeInputRangesAndControllers() {
    for (var input in _inputs) {
      if (input is SMINumber) {
        double minVal = 0.0;
        double maxVal = 100.0;
        // Define default slider range based on initial value
        if (input.value > 100.0) {
          maxVal = input.value * 1.5;
        } else if (input.value < 0.0) {
          minVal = input.value * 1.5;
        } else if (input.value != 0.0 &&
            input.value < 1.0 &&
            input.value > -1.0) {
          // Handle small fractional values reasonably
          minVal = -1.0;
          maxVal = 1.0;
        }

        _numberInputRanges[input.name] = RangeValues(minVal, maxVal);
        _minControllers[input.name] =
            TextEditingController(text: minVal.toStringAsFixed(2));
        _maxControllers[input.name] =
            TextEditingController(text: maxVal.toStringAsFixed(2));
      }
    }
  }

  void updateNumberInput(SMINumber input, double value) {
    input.value = value;
    notifyListeners(); // Update UI to reflect slider/value change
  }

  void updateNumberRange(String inputName, String minStr, String maxStr) {
    final double? minVal = double.tryParse(minStr);
    final double? maxVal = double.tryParse(maxStr);

    if (minVal != null && maxVal != null && minVal <= maxVal) {
      _numberInputRanges[inputName] = RangeValues(minVal, maxVal);
      // Optionally clamp the current value if it falls outside the new range
      final input =
          _inputs.firstWhere((i) => i.name == inputName && i is SMINumber)
              as SMINumber?;
      if (input != null) {
        input.value = input.value.clamp(minVal, maxVal);
      }
      notifyListeners(); // Update slider range and possibly value
    } else {
      // Maybe show a temporary error or revert the text fields?
      // For now, just don't update if invalid
      debugPrint(
          "Invalid range provided for $inputName: min=$minStr, max=$maxStr");
      // Revert text fields to current valid range
      final currentRange = _numberInputRanges[inputName];
      if (currentRange != null) {
        _minControllers[inputName]?.text =
            currentRange.start.toStringAsFixed(2);
        _maxControllers[inputName]?.text = currentRange.end.toStringAsFixed(2);
      }
    }
  }

  void updateBoolInput(SMIBool input, bool value) {
    input.value = value;
    notifyListeners(); // Update UI to reflect switch change
  }

  void fireTriggerInput(SMITrigger input) {
    try {
      input.fire();
      // Optionally add visual feedback or notifyListeners if needed
      // Often triggers cause visual changes handled by Rive itself
      debugPrint("Fired trigger: ${input.name}");
    } catch (e) {
      debugPrint("Error firing trigger ${input.name}: $e");
      _setError("Error firing trigger ${input.name}: ${e.toString()}");
    }
  }

  void toggleSimpleAnimationPlayback() {
    if (_simpleAnimationController != null) {
      _simpleAnimationController!.isActive =
          !_simpleAnimationController!.isActive;
      notifyListeners(); // Update Play/Pause button UI
    }
  }

  // Dispose method for the controller
  @override
  void dispose() {
    _stateMachineController?.dispose();
    _simpleAnimationController?.dispose();
    _minControllers.forEach((_, ctrl) => ctrl.dispose());
    _maxControllers.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
  }
}
