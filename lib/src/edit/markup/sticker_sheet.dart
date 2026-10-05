import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// the developer's stickers in a grid, a tap gives back its index.
class StickerSheet extends StatelessWidget {
  const StickerSheet({super.key});

  static Future<int?> show(BuildContext context) {
    final scope = PickerScope.of(context);
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: scope.theme.surface,
      builder: (_) => scope.wrap(const StickerSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final stickers = scope.settings.markup.stickers;
    return SafeArea(
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(PickerLayout.padding),
        itemCount: stickers.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 88,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => Semantics(
          button: true,
          label: scope.texts.stickers,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(index),
            child: Image(
              image: stickers[index],
              fit: BoxFit.contain,
              // a sticker that can't load is left out
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
