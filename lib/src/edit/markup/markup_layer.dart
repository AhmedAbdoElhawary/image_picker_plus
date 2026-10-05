import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';

/// the markup over an image, sized like the whole image so the crop moves it with the photo.
class MarkupLayer extends StatelessWidget {
  final MarkupController controller;

  /// an item being moved, drawn where it is now until the move ends.
  final ValueListenable<(MarkupItem, MarkupItem)?>? moving;

  /// left out, like a text open in the editor.
  final MarkupItem? hidden;

  /// the stroke being drawn.
  final ValueListenable<StrokeMark?>? active;

  const MarkupLayer({required this.controller, this.moving, this.hidden, this.active, super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, moving, active]),
        builder: (context, _) {
          final moving = this.moving?.value;
          final items = [
            for (final item in controller.value)
              if (item != hidden) moving != null && item == moving.$1 ? moving.$2 : item,
          ];
          return CustomPaint(
            size: Size.infinite,
            painter: MarkupPainter(items: items, active: active?.value),
          );
        },
      ),
    );
  }
}
