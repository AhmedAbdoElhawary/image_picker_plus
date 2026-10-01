import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// placeholder with a light band moving over the surface color.
class LoadingBox extends StatefulWidget {
  const LoadingBox({super.key});

  @override
  State<LoadingBox> createState() => _LoadingBoxState();
}

class _LoadingBoxState extends State<LoadingBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final x = _controller.value * 3 - 1.5;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: [theme.surface, Color.lerp(theme.surface, theme.background, 0.6)!, theme.surface],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
