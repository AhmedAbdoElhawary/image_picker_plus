import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// placeholder with a light band moving over the surface color.
class LoadingBox extends StatefulWidget {
  const LoadingBox({super.key});

  @override
  State<LoadingBox> createState() => _LoadingBoxState();
}

class _LoadingBoxState extends State<LoadingBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    // painted from the animation, a grid full of these would rebuild every frame otherwise
    return CustomPaint(
      size: Size.infinite,
      painter: _BandPainter(
        animation: _controller,
        color: theme.surface,
        band: Color.lerp(theme.surface, theme.background, 0.6)!,
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final Color band;

  _BandPainter({required this.animation, required this.color, required this.band})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final x = animation.value * 3 - 1.5;
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment(x - 1, 0),
      end: Alignment(x + 1, 0),
      colors: [color, band, color],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.animation != animation || old.color != color || old.band != band;
}
