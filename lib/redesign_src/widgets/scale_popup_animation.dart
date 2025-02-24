import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_manager.dart';

class ScalePopupAnimationWidget extends StatefulWidget {
  final Widget? child;
  final Duration duration;
  final bool isAnimating;
  final bool scaleBigger;
  final bool reverseAfterFinish;
  final VoidCallback? onEnd;
  const ScalePopupAnimationWidget({
    this.child,
    this.onEnd,
    this.scaleBigger = true,
    this.reverseAfterFinish = false,
    this.duration = const Duration(milliseconds: 200),
    required this.isAnimating,
    super.key,
  });

  @override
  State<ScalePopupAnimationWidget> createState() => _ScalePopupAnimationWidgetState();
}

class _ScalePopupAnimationWidgetState extends State<ScalePopupAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> scale;
  @override
  void initState() {
    super.initState();
    final halfDuration = widget.duration.inMilliseconds ~/ 2;
    animationController = AnimationController(duration: Duration(milliseconds: halfDuration), vsync: this);
    if (widget.scaleBigger) {
      scale = Tween<double>(begin: 1, end: 1.2).animate(animationController);
    } else {
      scale = Tween<double>(begin: 1, end: 0.85).animate(animationController);
    }
  }

  @override
  void didUpdateWidget(ScalePopupAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      widget.isAnimating ? doAnimation() : removeAnimation();
    }
  }

  @override
  void deactivate() {
    animationController.stop();
    super.deactivate();
  }

  Future doAnimation() async {
    if (widget.isAnimating || widget.reverseAfterFinish) {
      await animationController.forward();
    }
    if (widget.reverseAfterFinish) await removeAnimation();
  }

  Future removeAnimation() async {
    if (!widget.isAnimating || widget.reverseAfterFinish) {
      await animationController.reverse();
      await Future.delayed(const Duration(milliseconds: 400));
      if (kDebugMode) print("remove animation :");

      final onEnd = widget.onEnd;
      if (onEnd != null) onEnd();
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scale,
      child: widget.child ??
          Icon(
            Icons.favorite_rounded,
            color: context.getColor(ThemeEnum.whiteColor),
            size: 100.r,
            shadows: [
              Shadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0.5, 0.5),
              ),
            ],
          ),
    );
  }
}
