import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';

/// the markup over an image, sized like the whole image so the crop moves it with the photo.
class MarkupLayer extends StatelessWidget {
  final MarkupController controller;

  /// an item being moved, left out until the move ends, it's drawn over the crop so it can go past the image.
  final ValueListenable<(MarkupItem, MarkupItem)?>? moving;

  /// left out, like a text open in the editor.
  final MarkupItem? hidden;

  /// the stroke being drawn.
  final ValueListenable<StrokeMark?>? active;

  const MarkupLayer({required this.controller, this.moving, this.hidden, this.active, super.key});

  @override
  Widget build(BuildContext context) {
    final active = this.active;
    final layer = ListenableBuilder(
      listenable: Listenable.merge([controller, moving]),
      builder: (context, _) {
        final moving = this.moving?.value;
        final items = [
          for (final item in controller.value)
            if (item != hidden && item != moving?.$1) item,
        ];
        return CustomPaint(
          size: Size.infinite,
          painter: MarkupPainter(items: items),
        );
      },
    );
    return IgnorePointer(
      child: active == null
          ? layer
          : Stack(
              fit: StackFit.expand,
              children: [
                layer,
                // its own layer, a finger move repaints the one stroke and not every stroke and text
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: MarkupPainter(items: const [], active: active),
                  ),
                ),
              ],
            ),
    );
  }
}
