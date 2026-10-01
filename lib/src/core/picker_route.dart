import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';

/// fade with a small slide up, instant with reduced motion.
class PickerRoute<T> extends PageRouteBuilder<T> {
  PickerRoute({required WidgetBuilder builder, required BuildContext context})
    : super(
        pageBuilder: (context, _, _) => builder(context),
        transitionDuration: PickerDurations.of(context).long,
        reverseTransitionDuration: PickerDurations.of(context).medium,
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      );
}
