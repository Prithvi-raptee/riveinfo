import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'rive_controller.dart';

class RiveForgePage extends StatelessWidget {
  const RiveForgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RiveController>(
      builder: (context, controller, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('RiveForge'),
            actions: [
              if (controller.isFileLoaded)
                IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  tooltip: 'Reload Rive File',
                  onPressed:
                      controller.isLoading ? null : controller.reloadRiveFile,
                  iconSize: 26,
                ),
              if (controller.isFileLoaded) const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.folder_open_outlined),
                tooltip: 'Pick Rive File (.riv)',
                onPressed: controller.isLoading ? null : controller.pickFile,
                iconSize: 28,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(context, controller, colorScheme),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, RiveController controller,
      ColorScheme colorScheme) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return _buildErrorWidget(context, controller, colorScheme);
    }
    if (controller.artboard == null) {
      return _buildInitialPrompt(context, controller, colorScheme);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainer,
              border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Rive(
              artboard: controller.artboard!,
              fit: BoxFit.contain,
              // We let the controllers handle playback
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12, bottom: 12, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFileInfoCard(context, controller),
                const SizedBox(height: 12),
                _buildStateMachineSelectorCard(context, controller),
                const SizedBox(height: 12),
                _buildAnimationSelectorCard(context, controller),
                const SizedBox(height: 12),
                _buildControlsCard(context, controller),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- UI Building Blocks ---

  Widget _buildErrorWidget(BuildContext context, RiveController controller,
      ColorScheme colorScheme) {
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
                      color: colorScheme.onErrorContainer, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.errorMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
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
          )),
    );
  }

  Widget _buildInitialPrompt(BuildContext context, RiveController controller,
      ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined,
              size: 70, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text('Pick a .riv file to start exploring',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Pick File'),
            onPressed: controller.pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoCard(BuildContext context, RiveController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (controller.fileName != null)
              Tooltip(
                message: controller.fileName!,
                child: Text(
                  controller.fileName!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Artboard: ${controller.artboard?.name ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateMachineSelectorCard(
      BuildContext context, RiveController controller) {
    final allStateMachineNames =
        controller.artboard?.stateMachines.map((sm) => sm.name).toList() ?? [];
    final uniqueStateMachineNames = allStateMachineNames.toSet().toList();

    if (uniqueStateMachineNames.isEmpty && allStateMachineNames.isEmpty) {
      return const SizedBox.shrink();
    }

    bool isSelectedValueDuplicated = false;
    if (controller.selectedStateMachineName != null) {
      final count = allStateMachineNames
          .where((name) => name == controller.selectedStateMachineName)
          .length;
      isSelectedValueDuplicated = count > 1;
    }
    String? dropdownValue =
        isSelectedValueDuplicated ? null : controller.selectedStateMachineName;
    String hintText =
        isSelectedValueDuplicated && controller.selectedStateMachineName != null
            ? '(Duplicate: ${controller.selectedStateMachineName})'
            : '(Select State Machine)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State Machines',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (uniqueStateMachineNames.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No state machines found in this artboard.',
                    style: Theme.of(context).textTheme.bodySmall),
              )
            else
              DropdownButtonFormField<String>(
                value: dropdownValue,
                decoration: InputDecoration(
                  hintText: hintText,
                ),
                items: uniqueStateMachineNames.map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name, overflow: TextOverflow.ellipsis),
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
            // Optional: Show full list if duplicates exist or for clarity
            if (allStateMachineNames.length != uniqueStateMachineNames.length)
              _buildExpansionList(
                  context,
                  "Full List (${allStateMachineNames.length})",
                  allStateMachineNames),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationSelectorCard(
      BuildContext context, RiveController controller) {
    final allAnimationNames =
        controller.artboard?.animations.map((anim) => anim.name).toList() ?? [];
    final uniqueAnimationNames = allAnimationNames.toSet().toList();

    if (uniqueAnimationNames.isEmpty && allAnimationNames.isEmpty) {
      return const SizedBox.shrink();
    }

    bool isSelectedValueDuplicated = false;
    if (controller.selectedAnimationName != null) {
      final count = allAnimationNames
          .where((name) => name == controller.selectedAnimationName)
          .length;
      isSelectedValueDuplicated = count > 1;
    }
    String? dropdownValue =
        isSelectedValueDuplicated ? null : controller.selectedAnimationName;
    String hintText =
        isSelectedValueDuplicated && controller.selectedAnimationName != null
            ? '(Duplicate: ${controller.selectedAnimationName})'
            : '(Select Simple Animation)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Simple Animations',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (uniqueAnimationNames.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No simple animations found in this artboard.',
                    style: Theme.of(context).textTheme.bodySmall),
              )
            else
              DropdownButtonFormField<String>(
                value: dropdownValue,
                decoration: InputDecoration(
                  hintText: hintText,
                ),
                items: uniqueAnimationNames.map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name, overflow: TextOverflow.ellipsis),
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
            _buildExpansionList(context,
                "Full List (${allAnimationNames.length})", allAnimationNames),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionList(
      BuildContext context, String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text(title, style: Theme.of(context).textTheme.labelSmall),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 16, bottom: 8, right: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      iconColor: Theme.of(context).colorScheme.primary,
      collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      children: items
          .map((name) =>
              Text("- $name", style: Theme.of(context).textTheme.bodySmall))
          .toList(),
    );
  }

  Widget _buildControlsCard(BuildContext context, RiveController controller) {
    if (controller.selectedStateMachineName != null &&
        controller.stateMachineController != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: controller.selectedStateMachineName!,
                child: Text(
                  'Inputs for "${controller.selectedStateMachineName}"',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              if (controller.inputs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No inputs found for this state machine.',
                      style: Theme.of(context).textTheme.bodySmall),
                )
              else
                ...controller.inputs
                    .map((input) =>
                        _buildInputControl(context, controller, input))
                    .toList(),
            ],
          ),
        ),
      );
    } else if (controller.selectedAnimationName != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Animation Control',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Tooltip(
                message: controller.selectedAnimationName!,
                child: Text('Playing: ${controller.selectedAnimationName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 16),
              if (controller.simpleAnimationController != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    icon: Icon(controller.simpleAnimationController!.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline),
                    label: Text(controller.simpleAnimationController!.isActive
                        ? 'Pause'
                        : 'Play'),
                    onPressed: controller.toggleSimpleAnimationPlayback,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // --- Input Control Widgets ---

  Widget _buildInputControl(
      BuildContext context, RiveController controller, SMIInput input) {
    if (input is SMINumber) {
      return _buildNumberInput(context, controller, input);
    } else if (input is SMIBool) {
      return _buildBooleanInput(context, controller, input);
    } else if (input is SMITrigger) {
      return _buildTriggerInput(context, controller, input);
    } else {
      return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('Unknown input: ${input.name}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic)),
          subtitle: Text('Type: ${input.runtimeType}',
              style: Theme.of(context).textTheme.labelSmall));
    }
  }

  Widget _buildNumberInput(
      BuildContext context, RiveController controller, SMINumber input) {
    final range = controller.numberInputRanges[input.name] ??
        const RangeValues(0.0, 100.0);
    final minVal = range.start;
    final maxVal = range.end;
    final currentSliderVal = input.value.clamp(minVal, maxVal);
    final minController = controller.minControllers[input.name];
    final maxController = controller.maxControllers[input.name];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${input.name}: ${input.value.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Slider(
            value: currentSliderVal,
            min: minVal,
            max: maxVal,
            divisions: (maxVal - minVal > 0 && (maxVal - minVal).isFinite)
                ? ((maxVal - minVal) * 20).round().clamp(1, 500)
                : null,
            label: input.value.toStringAsFixed(2),
            onChanged: (double value) {
              controller.updateNumberInput(input, value);
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Range:', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRangeTextField(
                  context,
                  controller,
                  input.name,
                  minController,
                  true,
                ),
              ),
              const SizedBox(width: 8),
              Text('-', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRangeTextField(
                  context,
                  controller,
                  input.name,
                  maxController,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeTextField(
    BuildContext context,
    RiveController controller,
    String inputName,
    TextEditingController? textController,
    bool isMin,
  ) {
    if (textController == null) return const SizedBox.shrink();

    return SizedBox(
      height: 35,
      child: TextField(
        controller: textController,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: isMin ? 'Min' : 'Max',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        onSubmitted: (_) {
          final minStr = controller.minControllers[inputName]?.text ?? '';
          final maxStr = controller.maxControllers[inputName]?.text ?? '';
          controller.updateNumberRange(inputName, minStr, maxStr);
        },
        onEditingComplete: () {
          final minStr = controller.minControllers[inputName]?.text ?? '';
          final maxStr = controller.maxControllers[inputName]?.text ?? '';
          controller.updateNumberRange(inputName, minStr, maxStr);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildBooleanInput(
      BuildContext context, RiveController controller, SMIBool input) {
    return ListTile(
      title: Text(input.name, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Switch(
        value: input.value,
        onChanged: (bool value) {
          controller.updateBoolInput(input, value);
        },
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTriggerInput(
      BuildContext context, RiveController controller, SMITrigger input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.bolt_outlined, size: 18),
          label: Text('Fire: ${input.name}'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: Theme.of(context).textTheme.labelMedium,
          ),
          onPressed: () {
            controller.fireTriggerInput(input);

            final snackBar = SnackBar(
              content: Text(controller.errorMessage == null
                  ? 'Triggered: ${input.name}'
                  : controller.errorMessage!),
              duration: Duration(
                  milliseconds: controller.errorMessage == null ? 900 : 2500),
              backgroundColor: controller.errorMessage != null
                  ? Theme.of(context).colorScheme.errorContainer
                  : null,

              // textColor: controller.errorMessage != null
              //     ? Theme.of(context).colorScheme.onErrorContainer
              //     : null,
            );
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            if (controller.errorMessage != null) controller.clearError();
          },
        ),
      ),
    );
  }
}
