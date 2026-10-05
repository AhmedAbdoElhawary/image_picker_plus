import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/capture_controller.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// tap to focus there with a ring, pinch to zoom.
class FocusArea extends StatefulWidget {
  final CaptureController controller;
  final Widget child;

  const FocusArea({required this.controller, required this.child, super.key});

  @override
  State<FocusArea> createState() => _FocusAreaState();
}

class _FocusAreaState extends State<FocusArea> {
  Offset? _point;

  /// a new ring for each tap, so it starts over.
  int _taps = 0;
  double _startZoom = 1;

  void _focus(TapUpDetails details) {
    final size = context.size!;
    final point = details.localPosition;
    widget.controller.focus(Offset(point.dx / size.width, point.dy / size.height));
    setState(() {
      _point = point;
      _taps++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _focus,
      onScaleStart: (_) => _startZoom = widget.controller.zoom.value,
      onScaleUpdate: (details) {
        // one finger is a drag, not a pinch
        if (details.pointerCount > 1) widget.controller.setZoom(_startZoom * details.scale);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          // not directional, the tap is from the left in rtl too
          if (point != null)
            Positioned(
              left: point.dx - _FocusRing.size / 2,
              top: point.dy - _FocusRing.size / 2,
              child: _FocusRing(key: ValueKey(_taps), onEnd: () => setState(() => _point = null)),
            ),
        ],
      ),
    );
  }
}

/// shrinks in, stays a moment, then fades out.
class _FocusRing extends StatelessWidget {
  static const double size = 64;

  final VoidCallback onEnd;

  const _FocusRing({required this.onEnd, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final grow = MediaQuery.maybeDisableAnimationsOf(context) == true ? 0.0 : 0.25;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 1),
        onEnd: onEnd,
        builder: (context, t, child) => Opacity(
          opacity: 1 - const Interval(0.7, 1).transform(t),
          child: Transform.scale(
            scale: 1 + grow * (1 - const Interval(0, 0.3, curve: Curves.easeOut).transform(t)),
            child: child,
          ),
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.onSurface, width: 1.5),
          ),
        ),
      ),
    );
  }
}
