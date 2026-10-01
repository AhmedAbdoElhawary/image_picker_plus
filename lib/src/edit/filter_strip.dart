import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

class FilterStrip extends StatelessWidget {
  final EditController controller;

  const FilterStrip({required this.controller, super.key});

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final pixels = (_size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ValueListenableBuilder<MediaItem>(
      valueListenable: controller.current,
      builder: (context, item, _) {
        final filter = controller.filterIndexes[item.id];
        final image = mediaImage(item, pixels, gallery: scope.services.gallery, cache: scope.services.cache);
        return IgnorePointer(
          ignoring: filter == null,
          child: AnimatedOpacity(
            opacity: filter == null ? 0.35 : 1,
            duration: PickerDurations.of(context).short,
            child: SizedBox(
              height: _size + 36,
              // a video has no filter, -1 marks none of the tiles
              child: ValueListenableBuilder<int>(
                valueListenable: filter ?? const AlwaysStoppedAnimation(-1),
                builder: (context, selected, _) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: PickerLayout.padding),
                  itemCount: filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => _FilterTile(
                    name: index < scope.texts.filterNames.length ? scope.texts.filterNames[index] : "",
                    matrix: filters[index],
                    image: image,
                    selected: index == selected,
                    onTap: () => controller.setFilter(index),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String name;
  final List<double> matrix;
  final ImageProvider image;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.name,
    required this.matrix,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: PickerDurations.of(context).short,
              width: FilterStrip._size,
              height: FilterStrip._size,
              padding: const EdgeInsetsDirectional.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PickerLayout.radius / 1.5),
                border: Border.all(color: selected ? theme.accent : theme.background, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PickerLayout.radius / 2),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(matrix),
                  child: Image(image: image, fit: BoxFit.cover, gaplessPlayback: true),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? theme.onSurface : theme.onSurfaceMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
