import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';

/// the markup over an image, sized like the whole image so the crop moves it with the photo.
class MarkupLayer extends StatefulWidget {
  final MarkupController controller;

  /// an item being moved, drawn where it is now until the move ends.
  final ValueListenable<(MarkupItem, MarkupItem)?>? moving;

  /// left out, like a text open in the editor.
  final MarkupItem? hidden;

  /// the stroke being drawn.
  final ValueListenable<StrokeMark?>? active;

  const MarkupLayer({required this.controller, this.moving, this.hidden, this.active, super.key});

  @override
  State<MarkupLayer> createState() => _MarkupLayerState();
}

class _MarkupLayerState extends State<MarkupLayer> {
  final Map<int, ui.Image> _stickers = {};
  final Set<int> _loading = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_loadStickers);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStickers();
  }

  @override
  void didUpdateWidget(MarkupLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_loadStickers);
    widget.controller.addListener(_loadStickers);
    _loadStickers();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_loadStickers);
    for (final image in _stickers.values) {
      image.dispose();
    }
    super.dispose();
  }

  void _loadStickers() {
    final providers = PickerScope.of(context).settings.markup.stickers;
    final configuration = createLocalImageConfiguration(context);
    for (final item in widget.controller.value) {
      if (item is! StickerMark || item.index >= providers.length) continue;
      if (_stickers.containsKey(item.index) || !_loading.add(item.index)) continue;
      resolveImage(providers[item.index], configuration).then((image) {
        if (image == null) return;
        if (!mounted) return image.dispose();
        setState(() => _stickers[item.index] = image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, widget.moving, widget.active]),
        builder: (context, _) {
          final moving = widget.moving?.value;
          final items = [
            for (final item in widget.controller.value)
              if (item != widget.hidden) moving != null && item == moving.$1 ? moving.$2 : item,
          ];
          return CustomPaint(
            size: Size.infinite,
            painter: MarkupPainter(items: items, stickers: _stickers, active: widget.active?.value),
          );
        },
      ),
    );
  }
}
