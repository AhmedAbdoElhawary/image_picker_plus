import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';

/// what's a bottom sheet on phones, in the middle of a big screen.
class PickerPopup extends StatelessWidget {
  final Color color;
  final Widget child;

  const PickerPopup({required this.color, required this.child, super.key});

  static const double maxWidth = 420;
  static const double maxHeight = 560;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: color,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(PickerLayout.radius * 2)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}
