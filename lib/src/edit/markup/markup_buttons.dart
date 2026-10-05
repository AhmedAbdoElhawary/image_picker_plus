import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

/// text, draw and emojis in the edit page's bar, each only when it's on, none for videos.
class MarkupButtons extends StatelessWidget {
  final EditController controller;

  const MarkupButtons({required this.controller, super.key});

  void _open(MarkupTool tool) {
    // the same tool again opens it again, a new text or the emoji sheet
    if (controller.tool.value == tool) controller.tool.value = null;
    controller.tool.value = tool;
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final markup = scope.settings.markup;
    return ValueListenableBuilder<MediaItem>(
      valueListenable: controller.current,
      builder: (context, item, _) {
        if (item.isVideo || controller.markups[item.id] == null) return const SizedBox.shrink();
        final color = scope.theme.onSurface;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (markup.text)
              IconButton(
                onPressed: () => _open(MarkupTool.text),
                tooltip: scope.texts.text,
                icon: Icon(Icons.text_fields_rounded, color: color),
              ),
            if (markup.drawing)
              IconButton(
                onPressed: () => _open(MarkupTool.draw),
                tooltip: scope.texts.draw,
                icon: Icon(Icons.brush_rounded, color: color),
              ),
            // an emoji is a text, so it comes with text
            if (markup.text)
              IconButton(
                onPressed: () => _open(MarkupTool.emoji),
                tooltip: scope.texts.emojis,
                icon: Icon(Icons.emoji_emotions_outlined, color: color),
              ),
          ],
        );
      },
    );
  }
}
