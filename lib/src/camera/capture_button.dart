import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// photo: tap. video: tap to start and stop, with a timer while recording.
class CaptureButton extends StatelessWidget {
  final bool video;
  final bool recording;
  final VoidCallback? onTap;

  const CaptureButton({required this.video, required this.recording, required this.onTap, super.key});

  static const double size = 76;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;
    final durations = PickerDurations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (video) _Timer(running: recording),
        Semantics(
          button: true,
          label: scope.texts.capture,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: durations.medium,
              width: size,
              height: size,
              padding: EdgeInsetsDirectional.all(recording ? 20 : 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.onSurface, width: 4),
              ),
              child: AnimatedContainer(
                duration: durations.medium,
                decoration: BoxDecoration(
                  color: theme.onSurface,
                  borderRadius: BorderRadius.circular(recording ? 6 : size),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Timer extends StatefulWidget {
  final bool running;

  const _Timer({required this.running});

  @override
  State<_Timer> createState() => _TimerState();
}

class _TimerState extends State<_Timer> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.running) _start();
  }

  @override
  void didUpdateWidget(_Timer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !oldWidget.running) _start();
    if (!widget.running && oldWidget.running) _stop();
  }

  void _start() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
  }

  void _stop() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final seconds = (_seconds % 60).toString().padLeft(2, "0");
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Opacity(
        opacity: widget.running ? 1 : 0,
        child: Text(
          "${_seconds ~/ 60}:$seconds",
          style: TextStyle(color: theme.onSurface, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}
