import 'package:flutter/widgets.dart';

/// places [child], sized like the whole image, so [rect] of it fills the box.
class CroppedImage extends StatelessWidget {
  final Rect rect;
  final Widget child;
  final bool clip;

  const CroppedImage({required this.rect, required this.child, this.clip = true, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / rect.width;
        final height = constraints.maxHeight / rect.height;
        final stack = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: -rect.left * width, top: -rect.top * height, width: width, height: height, child: child),
          ],
        );
        return clip ? ClipRect(child: stack) : stack;
      },
    );
  }
}
