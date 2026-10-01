import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';

/// preview above the grid on phones, beside it on wide screens.
class GalleryLayout extends StatelessWidget {
  final Widget preview;
  final Widget grid;

  const GalleryLayout({required this.preview, required this.grid, super.key});

  @override
  Widget build(BuildContext context) {
    if (PickerLayout.of(context).previewBeside) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(PickerLayout.padding),
              child: ClipRRect(borderRadius: BorderRadius.circular(PickerLayout.radius), child: preview),
            ),
          ),
          Expanded(child: grid),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          // square, but never more than half the height so the grid stays usable
          SizedBox(height: min(constraints.maxWidth, constraints.maxHeight / 2), child: preview),
          const SizedBox(height: PickerLayout.gap),
          Expanded(child: grid),
        ],
      ),
    );
  }
}
