import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import 'app_theme.dart'; // Assuming app_theme.dart is in the same directory
import 'rive_controller.dart'; // Assuming rive_controller.dart is available

class RiveForgePage extends StatelessWidget {
  const RiveForgePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access theme data and color scheme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Access custom card themes
    final cardThemes = Theme.of(context).extension<CardThemes>();

    return Consumer<RiveController>(
      builder: (context, controller, child) {
        return Scaffold(
          // Use scaffoldBackgroundColor from theme
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('RiveForge'),
            // AppBar theme is applied globally via AppTheme
            actions: [
              // Reload Button
              if (controller.isFileLoaded)
                IconButton(
                  icon: const Icon(Icons.replay_outlined), // Changed icon
                  tooltip: 'Reload Rive File',
                  onPressed:
                      controller.isLoading ? null : controller.reloadRiveFile,
                  iconSize: 26,
                ),
              if (controller.isFileLoaded) const SizedBox(width: 4),
              // Pick File Button
              IconButton(
                icon: const Icon(Icons.folder_open_outlined),
                tooltip: 'Pick Rive File (.riv)',
                onPressed: controller.isLoading ? null : controller.pickFile,
                iconSize: 28,
              ),
              const SizedBox(width: 12), // Increased spacing
            ],
          ),
          body: _buildBody(context, controller, theme, colorScheme, cardThemes),
        );
      },
    );
  }

  // --- Body Builder ---
  Widget _buildBody(BuildContext context, RiveController controller,
      ThemeData theme, ColorScheme colorScheme, CardThemes? cardThemes) {
    // --- Loading State ---
    if (controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading Rive file..."),
          ],
        ),
      );
    }

    // --- Error State ---
    if (controller.errorMessage != null && !controller.isFileLoaded) {
      // Show full page error only if file loading failed initially
      return _buildErrorWidget(context, controller, theme, colorScheme);
    }

    // --- Initial Prompt State ---
    if (controller.artboard == null) {
      return _buildInitialPrompt(context, controller, theme, colorScheme);
    }

    // --- Main Content State ---
    return Padding(
      // Add overall padding for the Row content
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Left Panel: Rive Canvas ---
          Expanded(
            flex: 3, // Adjust flex ratio as needed
            child: Padding(
              padding:
                  const EdgeInsets.all(8.0), // Padding around the canvas card
              child: Card(
                // Use the default CardTheme defined in AppTheme
                // Or optionally use cardThemes?.outlined
                elevation: cardThemes?.outlined?.elevation ?? 2,
                shape: cardThemes?.outlined?.shape,
                clipBehavior: Clip.antiAlias,
                color: colorScheme.surface, // Background for canvas area
                child: Rive(
                  artboard: controller.artboard!,
                  fit: BoxFit.contain,
                  // Controllers are managed by RiveController
                ),
              ),
            ),
          ),

          // --- Right Panel: Controls ---
          Expanded(
            flex: 2, // Adjust flex ratio as needed
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, right: 8.0, bottom: 8.0), // Padding for controls
              child: ListView(
                // Use ListView for scrolling controls
                children: [
                  // --- File Info Card ---
                  _buildFileInfoCard(context, controller, theme, colorScheme,
                      cardThemes?.filled),
                  const SizedBox(height: 12),

                  // --- State Machine Selector ---
                  _buildStateMachineSelectorCard(context, controller, theme,
                      colorScheme, cardThemes?.filled),
                  const SizedBox(height: 12),

                  // --- Animation Selector ---
                  _buildAnimationSelectorCard(context, controller, theme,
                      colorScheme, cardThemes?.filled),
                  const SizedBox(height: 12),

                  // --- Dynamic Controls Card (Inputs or Simple Playback) ---
                  _buildControlsCard(context, controller, theme, colorScheme,
                      cardThemes?.outlined),
                  const SizedBox(height: 12), // Padding at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Building Blocks ---

  // --- Error Widget ---
  Widget _buildErrorWidget(BuildContext context, RiveController controller,
      ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          // Use error colors from the theme
          color: colorScheme.errorContainer,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: colorScheme.onErrorContainer, size: 56),
                const SizedBox(height: 20),
                Text(
                  'Loading Failed',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage ??
                      "An unknown error occurred.", // Provide default
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Use ElevatedButton with error styling
                ElevatedButton.icon(
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Pick Different File'),
                  onPressed: controller.pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Initial Prompt Widget ---
  Widget _buildInitialPrompt(BuildContext context, RiveController controller,
      ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined,
              size: 80, color: colorScheme.primary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            'Explore Rive Animations',
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a .riv file to begin',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Use FilledButton (default primary color)
          FilledButton.icon(
            icon: const Icon(Icons.folder_open_outlined, size: 20),
            label: const Text('Pick File'),
            onPressed: controller.pickFile,
          ),
        ],
      ),
    );
  }

  // --- File Info Card ---
  Widget _buildFileInfoCard(BuildContext context, RiveController controller,
      ThemeData theme, ColorScheme colorScheme, CardTheme? cardStyle) {
    return Card(
      elevation: cardStyle?.elevation ?? 1,
      shape: cardStyle?.shape,
      color: cardStyle?.color ??
          colorScheme.surfaceContainerHighest, // Use filled style bg
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // Add icon to header
              children: [
                Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('File Info', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.fileName != null)
              Tooltip(
                message: controller.fileName!,
                child: Text(
                  'Name: ${controller.fileName!}',
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Artboard: ${controller.artboard?.name ?? 'N/A'}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // --- State Machine Selector Card ---
  Widget _buildStateMachineSelectorCard(
      BuildContext context,
      RiveController controller,
      ThemeData theme,
      ColorScheme colorScheme,
      CardTheme? cardStyle) {
    final allStateMachineNames =
        controller.artboard?.stateMachines.map((sm) => sm.name).toList() ?? [];
    // Always show unique names in dropdown
    final uniqueStateMachineNames = allStateMachineNames.toSet().toList();

    // Don't render card if no state machines
    if (allStateMachineNames.isEmpty) return const SizedBox.shrink();

    // Determine current dropdown value (must be one of the unique names)
    String? dropdownValue =
        uniqueStateMachineNames.contains(controller.selectedStateMachineName)
            ? controller.selectedStateMachineName
            : null;

    return Card(
      elevation: cardStyle?.elevation ?? 1,
      shape: cardStyle?.shape,
      color: cardStyle?.color ?? colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // Add icon to header
              children: [
                Icon(Icons.account_tree_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('State Machines', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            // Dropdown using unique names
            DropdownButtonFormField<String>(
              value: dropdownValue,
              // Decoration uses InputDecorationTheme from AppTheme
              decoration: const InputDecoration(
                hintText: 'Select State Machine',
              ),
              // Use canvasColor from theme for dropdown menu background
              dropdownColor: theme.canvasColor,
              items: uniqueStateMachineNames.map((name) {
                // Check for duplicates to potentially add info later if needed
                final count =
                    allStateMachineNames.where((n) => n == name).length;
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                      name + (count > 1 ? " (*)" : ""), // Indicate duplicates
                      overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: controller.isLoading
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        controller.selectStateMachine(newValue);
                      }
                    },
              isExpanded: true,
            ),
            const SizedBox(height: 4),
            // Always show the ExpansionTile with the full list
            _buildExpansionList(
              context,
              theme,
              colorScheme,
              "View All (${allStateMachineNames.length})", // Title shows total count
              allStateMachineNames,
              Icons.list_alt_rounded, // Specific icon
            ),
          ],
        ),
      ),
    );
  }

  // --- Animation Selector Card ---
  Widget _buildAnimationSelectorCard(
      BuildContext context,
      RiveController controller,
      ThemeData theme,
      ColorScheme colorScheme,
      CardTheme? cardStyle) {
    final allAnimationNames =
        controller.artboard?.animations.map((anim) => anim.name).toList() ?? [];
    final uniqueAnimationNames = allAnimationNames.toSet().toList();

    // Don't render card if no animations
    if (allAnimationNames.isEmpty) return const SizedBox.shrink();

    // Determine current dropdown value
    String? dropdownValue =
        uniqueAnimationNames.contains(controller.selectedAnimationName)
            ? controller.selectedAnimationName
            : null;

    return Card(
      elevation: cardStyle?.elevation ?? 1,
      shape: cardStyle?.shape,
      color: cardStyle?.color ?? colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // Add icon to header
              children: [
                Icon(Icons.slideshow_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Simple Animations', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            // Dropdown using unique names
            DropdownButtonFormField<String>(
              value: dropdownValue,
              decoration: const InputDecoration(
                hintText: 'Select Simple Animation',
              ),
              dropdownColor: theme.canvasColor,
              items: uniqueAnimationNames.map((name) {
                final count = allAnimationNames.where((n) => n == name).length;
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                      name + (count > 1 ? " (*)" : ""), // Indicate duplicates
                      overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: controller.isLoading
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        controller.selectAnimation(newValue);
                      }
                    },
              isExpanded: true,
            ),
            const SizedBox(height: 4),
            // Always show the ExpansionTile with the full list
            _buildExpansionList(
              context,
              theme,
              colorScheme,
              "View All (${allAnimationNames.length})",
              allAnimationNames,
              Icons.list_rounded, // Specific icon
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Expansion List for Full Names ---
  Widget _buildExpansionList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    List<String> items,
    IconData titleIcon, // Add icon parameter
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Count duplicates for display
    final itemCounts = <String, int>{};
    for (var item in items) {
      itemCounts[item] = (itemCounts[item] ?? 0) + 1;
    }

    return ExpansionTile(
      title: Text(title, style: theme.textTheme.labelMedium),
      leading: Icon(titleIcon,
          size: 18, color: colorScheme.primary), // Use leading icon
      tilePadding:
          const EdgeInsets.symmetric(horizontal: 4.0), // Adjust padding
      childrenPadding: const EdgeInsets.only(
          left: 24, bottom: 8, right: 8), // Indent children
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      iconColor: colorScheme.primary, // Expansion icon color
      collapsedIconColor: colorScheme.onSurfaceVariant,
      children: items.asMap().entries.map((entry) {
        // Use asMap for index access if needed
        final name = entry.value;
        final isDuplicate = (itemCounts[name] ?? 0) > 1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            "- $name ${isDuplicate ? '(*)' : ''}", // Mark duplicates clearly
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: isDuplicate ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Controls Card (State Machine Inputs or Simple Animation Playback) ---
  Widget _buildControlsCard(BuildContext context, RiveController controller,
      ThemeData theme, ColorScheme colorScheme, CardTheme? cardStyle) {
    // --- State Machine Input Controls ---
    if (controller.selectedStateMachineName != null &&
        controller.stateMachineController != null) {
      return Card(
        elevation: cardStyle?.elevation ?? 1,
        shape: cardStyle?.shape,
        color: cardStyle?.color ?? colorScheme.surface, // Use outlined style bg
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // Header with icon
                children: [
                  Icon(Icons.tune_rounded,
                      size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    // Allow title to wrap if needed
                    child: Tooltip(
                      message: controller.selectedStateMachineName!,
                      child: Text(
                        'Inputs: "${controller.selectedStateMachineName}"',
                        style: theme.textTheme.titleMedium,
                        maxLines: 2, // Allow wrapping
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(), // Visually separate header
              const SizedBox(height: 10),
              if (controller.inputs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No inputs found for this state machine.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                // Use ListView.builder if list can be very long, otherwise Column is fine
                ...controller.inputs.map(
                  (input) => Padding(
                    // Add padding between controls
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: _buildInputControl(
                        context, controller, input, theme, colorScheme),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    // --- Simple Animation Playback Controls ---
    else if (controller.selectedAnimationName != null) {
      return Card(
        elevation: cardStyle?.elevation ?? 1,
        shape: cardStyle?.shape,
        color: cardStyle?.color ?? colorScheme.surface, // Use outlined style bg
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // Header with icon
                children: [
                  Icon(Icons.play_circle_outline_rounded,
                      size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Animation Control',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              Tooltip(
                message: controller.selectedAnimationName!,
                child: Text(
                  'Playing: ${controller.selectedAnimationName}',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              if (controller.simpleAnimationController != null)
                Align(
                  alignment: Alignment.centerLeft,
                  // Use FilledButton.tonal for a less prominent action
                  child: FilledButton.tonalIcon(
                      icon: Icon(controller.simpleAnimationController!.isActive
                          ? Icons.pause_rounded // Use rounded icons
                          : Icons.play_arrow_rounded),
                      label: Text(controller.simpleAnimationController!.isActive
                          ? 'Pause'
                          : 'Play'),
                      onPressed: controller.toggleSimpleAnimationPlayback,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12), // Adjust padding
                        textStyle: theme.textTheme.labelLarge,
                      )),
                ),
            ],
          ),
        ),
      );
    } else {
      // No state machine or animation selected, show nothing or a placeholder
      return const SizedBox.shrink();
    }
  }

  // --- Input Control Widgets ---

  // Helper to build individual input controls based on type
  Widget _buildInputControl(BuildContext context, RiveController controller,
      SMIInput input, ThemeData theme, ColorScheme colorScheme) {
    if (input is SMINumber) {
      return _buildNumberInput(context, controller, input, theme, colorScheme);
    } else if (input is SMIBool) {
      return _buildBooleanInput(context, controller, input, theme, colorScheme);
    } else if (input is SMITrigger) {
      return _buildTriggerInput(context, controller, input, theme, colorScheme);
    } else {
      // Fallback for unknown input types
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.help_outline, color: colorScheme.onSurfaceVariant),
        title: Text('Unknown Input: ${input.name}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontStyle: FontStyle.italic)),
        subtitle: Text('Type: ${input.runtimeType}',
            style: theme.textTheme.labelSmall),
      );
    }
  }

  // --- Number Input Widget (Slider + Range Fields) ---
  Widget _buildNumberInput(BuildContext context, RiveController controller,
      SMINumber input, ThemeData theme, ColorScheme colorScheme) {
    // Get range, defaulting safely
    final range = controller.numberInputRanges[input.name] ??
        const RangeValues(0.0, 100.0);
    final minVal = range.start.isFinite ? range.start : 0.0;
    final maxVal =
        range.end.isFinite && range.end > minVal ? range.end : minVal + 100.0;

    // Clamp current value to the effective range
    final currentSliderVal = input.value.clamp(minVal, maxVal);

    // Determine divisions for the slider for snapping effect
    int? divisions;
    final rangeDiff = maxVal - minVal;
    if (rangeDiff > 0 && rangeDiff.isFinite) {
      // Aim for roughly 20 steps per 100 units, clamped
      divisions = (rangeDiff * 0.2).round().clamp(5, 500);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Name and Value
        Text(
          '${input.name}: ${input.value.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500), // Slightly bolder label
        ),
        const SizedBox(height: 8),

        // Slider Control
        Slider(
          value: currentSliderVal,
          min: minVal,
          max: maxVal,
          divisions: divisions,
          label: input.value.toStringAsFixed(2), // Shown in the value indicator
          onChanged: (double value) {
            controller.updateNumberInput(input, value);
          },
          // SliderTheme applied globally via AppTheme
        ),
        const SizedBox(height: 8),

        // Range Input Fields
        Row(
          children: [
            Text('Range:',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRangeTextField(
                context,
                controller,
                input.name,
                controller.minControllers[input.name], // Get controller
                true, // isMin = true
                theme,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('-',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: _buildRangeTextField(
                context,
                controller,
                input.name,
                controller.maxControllers[input.name], // Get controller
                false, // isMin = false
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper: Range Text Field for Number Input ---
  Widget _buildRangeTextField(
    BuildContext context,
    RiveController controller,
    String inputName,
    TextEditingController? textController,
    bool isMin,
    ThemeData theme,
  ) {
    if (textController == null) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: TextField(
        controller: textController,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
        ],
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: isMin ? 'Min' : 'Max',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        // --- START MODIFICATION ---
        onSubmitted: (_) {
          // Fetch text from both controllers and call updateNumberRange
          final minStr = controller.minControllers[inputName]?.text ?? '';
          final maxStr = controller.maxControllers[inputName]?.text ?? '';
          controller.updateNumberRange(inputName, minStr, maxStr);
        },
        onEditingComplete: () {
          // Fetch text from both controllers and call updateNumberRange
          final minStr = controller.minControllers[inputName]?.text ?? '';
          final maxStr = controller.maxControllers[inputName]?.text ?? '';
          controller.updateNumberRange(inputName, minStr, maxStr);
          FocusScope.of(context).unfocus(); // Hide keyboard
        },
        // --- END MODIFICATION ---
      ),
    );
  }

  // --- Boolean Input Widget (Switch) ---
  Widget _buildBooleanInput(BuildContext context, RiveController controller,
      SMIBool input, ThemeData theme, ColorScheme colorScheme) {
    // Use SwitchListTile for better alignment and standard look
    return SwitchListTile(
      title: Text(input.name, style: theme.textTheme.bodyMedium),
      value: input.value,
      onChanged: (bool value) {
        controller.updateBoolInput(input, value);
      },
      // Use theme colors
      activeColor: colorScheme.primary,
      // dense: true, // Make it slightly more compact
      contentPadding: EdgeInsets.zero, // Remove default padding
      visualDensity: VisualDensity.compact, // Further reduce vertical space
    );
  }

  // --- Trigger Input Widget (Button) ---
  Widget _buildTriggerInput(BuildContext context, RiveController controller,
      SMITrigger input, ThemeData theme, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      // Use FilledButton.tonal for a softer action button
      child: FilledButton.tonalIcon(
        icon: const Icon(Icons.bolt_rounded, size: 18), // Rounded icon
        label: Text('Fire: ${input.name}'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10), // Adjusted padding
          textStyle: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // Store context before async gap
          final messenger = ScaffoldMessenger.of(context);
          // Fire the trigger
          controller.fireTriggerInput(input);

          // Check for error *after* firing
          final error = controller.errorMessage;
          final bool success = error == null;

          // Show Snackbar feedback
          final snackBar = SnackBar(
            content: Text(success ? 'Triggered: ${input.name}' : error!),
            duration: Duration(
                milliseconds: success ? 1200 : 3000), // Longer for errors
            // Use themed colors for success/error
            backgroundColor: success
                ? colorScheme
                    .primaryContainer // Or choose another success indicator color
                : colorScheme.errorContainer,
            // Text color adjusts automatically based on background in M3 SnackBar
            // action: SnackBarAction(label: "OK", onPressed: (){}), // Optional action
          );
          messenger.hideCurrentSnackBar(); // Remove previous snackbar first
          messenger.showSnackBar(snackBar);

          // Clear error state in controller if one occurred
          if (!success) controller.clearError();
        },
      ),
    );
  }
}
