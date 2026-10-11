import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/adjust_strip.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/filter_strip.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

/// the filter strip, the sliders, or a switch between them when both are on.
/// the sliders' reset sits at the end of the switch row.
class EditTools extends StatefulWidget {
  final EditController controller;

  const EditTools({required this.controller, super.key});

  @override
  State<EditTools> createState() => _EditToolsState();
}

class _EditToolsState extends State<EditTools> {
  bool _adjusting = false;
  final ValueNotifier<AdjustSlider> _picked = ValueNotifier(AdjustSlider.brightness);

  @override
  void dispose() {
    _picked.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final filters = scope.settings.filters.isNotEmpty;
    final adjustments = scope.settings.adjustments;
    if (!filters && !adjustments) return const SizedBox.shrink();
    if (!adjustments) return FilterStrip(controller: widget.controller);
    final adjusting = _adjusting || !filters;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: PickerLayout.padding),
          child: Row(
            children: [
              const Spacer(),
              if (filters) ...[
                _Tab(
                  label: scope.texts.filters,
                  picked: !_adjusting,
                  onTap: () => setState(() => _adjusting = false),
                ),
                _Tab(
                  label: scope.texts.adjust,
                  picked: _adjusting,
                  onTap: () => setState(() => _adjusting = true),
                ),
              ],
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: adjusting ? _Reset(controller: widget.controller, picked: _picked) : null,
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: PickerDurations.of(context).short,
          child: adjusting
              ? AdjustStrip(key: const ValueKey(true), controller: widget.controller, picked: _picked)
              : FilterStrip(key: const ValueKey(false), controller: widget.controller),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool picked;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.picked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return Semantics(
      selected: picked,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: picked ? theme.onSurface : theme.onSurfaceMuted),
        child: Text(label, style: TextStyle(fontWeight: picked ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

/// puts the picked slider of the current image back at 0, hidden while it's there.
class _Reset extends StatelessWidget {
  final EditController controller;
  final ValueNotifier<AdjustSlider> picked;

  const _Reset({required this.controller, required this.picked});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<MediaItem>(
      valueListenable: controller.current,
      builder: (context, item, _) {
        final notifier = controller.adjustments[item.id];
        return ListenableBuilder(
          listenable: Listenable.merge([notifier, picked]),
          builder: (context, _) {
            final moved = notifier != null && picked.value.valueOf(notifier.value) != 0;
            return AnimatedOpacity(
              opacity: moved ? 1 : 0,
              duration: PickerDurations.of(context).short,
              child: TextButton(
                onPressed: moved ? () => notifier.value = picked.value.apply(notifier.value, 0) : null,
                style: TextButton.styleFrom(foregroundColor: scope.theme.accent),
                child: Text(scope.texts.reset),
              ),
            );
          },
        );
      },
    );
  }
}
