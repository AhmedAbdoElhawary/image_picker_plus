import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/gallery/gallery_cell.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

class GalleryGrid extends StatelessWidget {
  final GalleryController controller;
  final void Function(MediaItem item) onTap;

  /// room for what floats over the grid, like the preview.
  final EdgeInsetsGeometry padding;

  const GalleryGrid({required this.controller, required this.onTap, this.padding = EdgeInsets.zero, super.key});

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final columns = settings.gridColumns ?? PickerLayout.of(context).columns;
    final aspect = settings.gridCellAspectRatio;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
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
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < (cellHeight + PickerLayout.gap) * 2) {
                    controller.loadMore();
                  }
                  return false;
                },
                child: GridView.builder(
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
                      onTap: () => onTap(item),
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
