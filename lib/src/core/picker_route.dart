import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';

/// fade with a small slide up, instant with reduced motion.
/// with a [barrier] it's a card over the app, not a full page.
class PickerRoute<T> extends PageRouteBuilder<T> {
  PickerRoute({required WidgetBuilder builder, required BuildContext context, Color? barrier})
    : super(
        opaque: barrier == null,
        barrierColor: barrier,
        // a stray click outside would lose the edits
        barrierDismissible: false,
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
