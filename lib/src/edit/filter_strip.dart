import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/edit/video_tile.dart';
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
        // a picked video can't be decoded as an image
        final image = item.isVideo && item.path != null
            ? null
            : mediaImage(item, pixels, gallery: scope.services.gallery, cache: scope.services.cache);
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

class _FilterTile extends StatefulWidget {
  final String name;
  final List<double> matrix;

  /// null shows a video tile.
  final ImageProvider? image;
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
  State<_FilterTile> createState() => _FilterTileState();
}

class _FilterTileState extends State<_FilterTile> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final selected = widget.selected;
    final image = widget.image;
    return Semantics(
      button: true,
      selected: selected,
      label: widget.name,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        // closer than the page's enter, so enter here picks the filter instead of done
        shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()},
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            children: [
              AnimatedContainer(
                duration: PickerDurations.of(context).short,
                width: FilterStrip._size,
                height: FilterStrip._size,
                padding: const EdgeInsetsDirectional.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PickerLayout.radius / 1.5),
                  border: Border.all(
                    color: selected || _focused
                        ? theme.accent
                        : (_hovered ? theme.onSurfaceMuted : theme.background),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PickerLayout.radius / 2),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(widget.matrix),
                    child: image == null
                        ? const VideoTile()
                        : Image(image: image, fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.name,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? theme.onSurface : theme.onSurfaceMuted,
                  fontSize: selected ? 12 : 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
