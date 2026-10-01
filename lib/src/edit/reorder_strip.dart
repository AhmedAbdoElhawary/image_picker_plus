import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

/// long press and drag to reorder, tap to edit that item.
class ReorderStrip extends StatelessWidget {
  final EditController controller;

  const ReorderStrip({required this.controller, super.key});

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return SizedBox(
      height: _size + 16,
      child: ValueListenableBuilder<List<MediaItem>>(
        valueListenable: controller.items,
        builder: (context, items, _) => ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: PickerLayout.padding, vertical: 8),
          buildDefaultDragHandles: false,
          itemCount: items.length,
          onReorderItem: controller.reorder,
          // the dragged copy is built in the overlay, outside the scope
          proxyDecorator: (child, _, _) => scope.wrap(child),
          itemBuilder: (context, index) => ReorderableDelayedDragStartListener(
            key: ValueKey(items[index].id),
            index: index,
            child: _Thumb(item: items[index], controller: controller),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final MediaItem item;
  final EditController controller;

  const _Thumb({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final pixels = (ReorderStrip._size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () => controller.current.value = item,
        child: Selector<bool>(
          listenable: controller.current,
          select: () => controller.current.value == item,
          builder: (context, current) => Container(
            width: ReorderStrip._size,
            height: ReorderStrip._size,
            padding: const EdgeInsetsDirectional.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: current ? scope.theme.accent : scope.theme.background, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image(
                image: mediaImage(item, pixels, gallery: scope.services.gallery, cache: scope.services.cache),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
