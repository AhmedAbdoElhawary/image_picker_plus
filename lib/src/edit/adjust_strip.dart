import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

/// the four sliders as icons, the picked one's slider above them.
class AdjustStrip extends StatefulWidget {
  final EditController controller;

  /// shared with the reset above the strip, which resets only this one.
  final ValueNotifier<AdjustSlider> picked;

  const AdjustStrip({required this.controller, required this.picked, super.key});

  /// the same height as the filter strip, so switching doesn't move the image.
  static const double height = 108;

  @override
  State<AdjustStrip> createState() => _AdjustStripState();
}

enum AdjustSlider {
  brightness,
  contrast,
  saturation,
  warmth;

  double valueOf(Adjustments adjustments) => switch (this) {
    brightness => adjustments.brightness,
    contrast => adjustments.contrast,
    saturation => adjustments.saturation,
    warmth => adjustments.warmth,
  };

  Adjustments apply(Adjustments adjustments, double value) => switch (this) {
    brightness => adjustments.copyWith(brightness: value),
    contrast => adjustments.copyWith(contrast: value),
    saturation => adjustments.copyWith(saturation: value),
    warmth => adjustments.copyWith(warmth: value),
  };
}

class _AdjustStripState extends State<AdjustStrip> {
  /// shown for a video, which has no sliders.
  final ValueNotifier<Adjustments> _none = ValueNotifier(Adjustments.neutral);

  @override
  void dispose() {
    _none.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final texts = scope.texts;
    final labels = {
      AdjustSlider.brightness: (texts.brightness, Icons.wb_sunny_outlined),
      AdjustSlider.contrast: (texts.contrast, Icons.contrast_rounded),
      AdjustSlider.saturation: (texts.saturation, Icons.water_drop_outlined),
      AdjustSlider.warmth: (texts.warmth, Icons.thermostat_rounded),
    };
    return ValueListenableBuilder<MediaItem>(
      valueListenable: widget.controller.current,
      builder: (context, item, _) {
        final notifier = widget.controller.adjustments[item.id];
        return IgnorePointer(
          ignoring: notifier == null,
          child: AnimatedOpacity(
            opacity: notifier == null ? 0.35 : 1,
            duration: PickerDurations.of(context).short,
            child: SizedBox(
              height: AdjustStrip.height,
              child: ListenableBuilder(
                listenable: Listenable.merge([notifier ?? _none, widget.picked]),
                builder: (context, _) {
                  final adjustments = (notifier ?? _none).value;
                  final picked = widget.picked.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: PickerLayout.padding),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            trackShape: const _CenterTrack(),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: SizedBox(
                            height: 36,
                            child: Slider(
                              value: picked.valueOf(adjustments),
                              min: -1,
                              semanticFormatterCallback: (value) =>
                                  "${labels[picked]!.$1} ${scope.texts.number((value * 100).round())}",
                              activeColor: scope.theme.onSurface,
                              inactiveColor: scope.theme.onSurfaceMuted.withValues(alpha: 0.4),
                              onChanged: (value) => notifier?.value = picked.apply(adjustments, value),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final slider in AdjustSlider.values)
                              _SliderButton(
                                label: labels[slider]!.$1,
                                icon: labels[slider]!.$2,
                                picked: slider == picked,
                                moved: slider.valueOf(adjustments) != 0,
                                onTap: () => widget.picked.value = slider,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SliderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool picked;

  /// not at 0, marked so the user sees which ones they changed.
  final bool moved;
  final VoidCallback onTap;

  const _SliderButton({
    required this.label,
    required this.icon,
    required this.picked,
    required this.moved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final color = picked ? theme.onSurface : theme.onSurfaceMuted;
    return Semantics(
      button: true,
      selected: picked,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PickerLayout.radius),
        child: SizedBox(
          width: PickerLayout.minTouch * 1.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: moved ? theme.accent : color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: picked ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 0 is in the middle, so the filled part runs from the middle to the thumb, either way.
class _CenterTrack extends RoundedRectSliderTrackShape {
  const _CenterTrack();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final track = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(track.height / 2);
    final middle = track.center.dx;
    final filled = Rect.fromLTRB(
      min(middle, thumbCenter.dx),
      track.top,
      max(middle, thumbCenter.dx),
      track.bottom,
    );
    context.canvas
      ..drawRRect(RRect.fromRectAndRadius(track, radius), Paint()..color = sliderTheme.inactiveTrackColor!)
      ..drawRRect(RRect.fromRectAndRadius(filled, radius), Paint()..color = sliderTheme.activeTrackColor!);
  }
}
