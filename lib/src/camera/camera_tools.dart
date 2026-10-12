import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/capture_controller.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';

/// 0.5x only when the camera goes below 1, the max only when it's past 2. fewer than two hides the row.
List<double> quickLevels(double low, double high) {
  final levels = [if (low < 1) max(low, 0.5), 1.0, if (high >= 2) 2.0, if (high > 2) high.floorToDouble()];
  final unique = levels.toSet().toList();
  return unique.length < 2 ? const [] : unique;
}

String _zoomLabel(double level) =>
    level == level.roundToDouble() ? "${level.toInt()}x" : "${level.toStringAsFixed(1)}x";

/// the active one shows the exact level while it's between two.
class ZoomButtons extends StatelessWidget {
  final CaptureController controller;

  const ZoomButtons({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    // a pinch sets the zoom many times a second, the row only changes at the 0.1 it shows
    return Selector<(double, double, double)>(
      listenable: Listenable.merge([controller.minZoom, controller.maxZoom, controller.zoom]),
      select: () =>
          (controller.minZoom.value, controller.maxZoom.value, (controller.zoom.value * 10).round() / 10),
      builder: (context, zooms, _) {
        final (low, high, zoom) = zooms;
        final levels = quickLevels(low, high);
        if (levels.isEmpty) return const SizedBox.shrink();
        // the highest level at or under the zoom, it shows the zoom when it's between levels
        final active = levels.lastWhere((level) => level <= zoom + 0.05, orElse: () => levels.first);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final level in levels)
              Semantics(
                button: true,
                selected: level == active,
                label: scope.texts.zoomLevelFor(_zoomLabel(level).replaceAll("x", "")),
                child: InkResponse(
                  onTap: () => controller.setZoom(level),
                  radius: PickerLayout.minTouch / 2,
                  child: SizedBox.fromSize(
                    size: const Size(PickerLayout.minTouch, PickerLayout.minTouch * 1.2),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scope.theme.background.withValues(alpha: 0.6),
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            scope.texts.number(level == active ? _zoomLabel(zoom) : _zoomLabel(level)),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: level == active ? scope.theme.accent : scope.theme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TimerButton extends StatelessWidget {
  final CaptureController controller;

  const TimerButton({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: controller.timer,
      builder: (context, seconds, _) => Semantics(
        value: seconds == 0 ? scope.texts.timerOff : scope.texts.timerSecondsFor(seconds),
        child: IconButton(
          onPressed: controller.cycleTimer,
          tooltip: scope.texts.timer,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                seconds == 0 ? Icons.timer_off_outlined : Icons.timer_outlined,
                color: seconds == 0 ? scope.theme.onSurface : scope.theme.accent,
                size: 26,
              ),
              if (seconds > 0)
                PositionedDirectional(
                  end: -6,
                  bottom: -4,
                  child: ExcludeSemantics(
                    child: Text(
                      scope.texts.number(seconds),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scope.theme.accent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridButton extends StatelessWidget {
  final ValueNotifier<bool> grid;

  const GridButton({required this.grid, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: grid,
      builder: (context, on, _) => IconButton(
        onPressed: () => grid.value = !on,
        tooltip: scope.texts.grid,
        isSelected: on,
        icon: Icon(
          on ? Icons.grid_on_rounded : Icons.grid_off_rounded,
          color: on ? scope.theme.accent : scope.theme.onSurface,
          size: 26,
        ),
      ),
    );
  }
}

/// rule of thirds over the preview, sized by the preview so it splits that and not the screen.
class GridLines extends StatelessWidget {
  const GridLines({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(PickerScope.of(context).theme.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  const _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final third in [1 / 3, 2 / 3]) {
      canvas.drawLine(Offset(size.width * third, 0), Offset(size.width * third, size.height), paint);
      canvas.drawLine(Offset(0, size.height * third), Offset(size.width, size.height * third), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}

class Countdown extends StatelessWidget {
  final CaptureController controller;

  const Countdown({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return IgnorePointer(
      child: ValueListenableBuilder<int?>(
        valueListenable: controller.countdown,
        builder: (context, seconds, _) => Center(
          child: AnimatedSwitcher(
            duration: PickerDurations.of(context).medium,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: 1.4, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: seconds == null
                ? const SizedBox.shrink()
                : Text(
                    scope.texts.number(seconds),
                    key: ValueKey(seconds),
                    style: TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w300,
                      color: scope.theme.onSurface,
                      shadows: [Shadow(color: scope.theme.background, blurRadius: 12)],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
