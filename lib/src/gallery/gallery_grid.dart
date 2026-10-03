import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/gallery/gallery_cell.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/gallery_scrollbar.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

class GalleryGrid extends StatefulWidget {
  final GalleryController controller;
  final void Function(MediaItem item) onTap;
  final void Function(MediaItem item) onLongPress;

  /// room for what floats over the grid, like the preview.
  final EdgeInsetsGeometry padding;

  /// how far the preview is slid up.
  final ValueListenable<double> collapse;

  const GalleryGrid({
    required this.controller,
    required this.onTap,
    required this.onLongPress,
    required this.collapse,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.album.addListener(_toTop);
  }

  @override
  void dispose() {
    widget.controller.album.removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  /// the preview follows the grid, so it shows fully again too.
  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final settings = controller.settings;
    final texts = PickerScope.of(context).texts;
    final columns = settings.gridColumns ?? PickerLayout.of(context).columns;
    final aspect = settings.gridCellAspectRatio;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final padding = widget.padding.resolve(Directionality.of(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - PickerLayout.gap * (columns - 1)) / columns;
        final cellHeight = cellWidth / aspect;
        // the thumbnail's short side is size, so it has to cover the cell's longer side
        final size = (max(cellWidth, cellHeight) * pixelRatio).ceil();
        return ValueListenableBuilder<List<MediaItem>>(
          valueListenable: controller.items,
          builder: (context, items, _) => ValueListenableBuilder<bool>(
            valueListenable: controller.ended,
            builder: (context, ended, _) {
              // one loading row at the end while more pages exist
              final count = ended ? items.length : items.length + columns;
              return GalleryScrollbar(
                controller: _scroll,
                top: padding.top,
                collapse: widget.collapse,
                label: (fraction) {
                  if (items.isEmpty) return null;
                  final item = items[(fraction * (items.length - 1)).round()];
                  return texts.monthOf(item.created ?? item.modified);
                },
                child: GridView.builder(
                  controller: _scroll,
                  padding: padding,
                  itemCount: count,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: aspect,
                    mainAxisSpacing: PickerLayout.gap,
                    crossAxisSpacing: PickerLayout.gap,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= items.length) return const LoadingBox();
                    final item = items[index];
                    return GalleryCell(
                      key: ValueKey(item.id),
                      item: item,
                      controller: controller,
                      size: size,
                      onTap: () => widget.onTap(item),
                      onLongPress: () => widget.onLongPress(item),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
