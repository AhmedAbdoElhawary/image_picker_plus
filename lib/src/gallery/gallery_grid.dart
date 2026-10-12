import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/gallery/gallery_cell.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/gallery_scrollbar.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

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
  final ValueNotifier<bool> _moving = ValueNotifier(false);
  late final ScrollPhysics _physics = _DeferPhysics(_moving);

  /// scrolls a tap started and hasn't finished, the preview doesn't slide up for them.
  int _tapScrolls = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.album.addListener(_toTop);
  }

  @override
  void dispose() {
    widget.controller.album.removeListener(_toTop);
    _scroll.dispose();
    _moving.dispose();
    super.dispose();
  }

  /// the preview follows the grid, so it shows fully again too.
  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// the tapped row goes right under the preview, which the tap shows fully again.
  Future<void> _scrollTo(double offset) async {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final to = offset.clamp(position.minScrollExtent, position.maxScrollExtent);
    final duration = PickerDurations.of(context).medium;
    _tapScrolls++;
    // a scroll animation can't be zero long
    duration == Duration.zero
        ? _scroll.jumpTo(to)
        : await _scroll.animateTo(to, duration: duration, curve: Curves.easeOutCubic);
    _tapScrolls--;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final settings = controller.settings;
    final scope = PickerScope.of(context);
    final texts = scope.texts;
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
              return NotificationListener<ScrollUpdateNotification>(
                onNotification: (_) => _tapScrolls > 0,
                child: GalleryScrollbar(
                  controller: _scroll,
                  moving: _moving,
                  top: padding.top,
                  collapse: widget.collapse,
                  label: (fraction) {
                    if (items.isEmpty) return null;
                    final item = items[(fraction * (items.length - 1)).round()];
                    return texts.monthOf(item.created ?? item.modified);
                  },
                  child: GridView.builder(
                    controller: _scroll,
                    physics: _physics,
                    padding: padding,
                    itemCount: count,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: aspect,
                      mainAxisSpacing: PickerLayout.gap,
                      crossAxisSpacing: PickerLayout.gap,
                    ),
                    itemBuilder: (context, index) {
                      if (index >= items.length) return ColoredBox(color: scope.theme.surface);
                      final item = items[index];
                      void toRow() {
                        // no top padding when the preview is beside or off, nothing to go under
                        if (padding.top > 0 && controller.preview.value == item) {
                          _scrollTo(index ~/ columns * (cellHeight + PickerLayout.gap));
                        }
                      }

                      return GalleryCell(
                        key: ValueKey(item.id),
                        item: item,
                        controller: controller,
                        size: size,
                        onTap: () {
                          widget.onTap(item);
                          toRow();
                        },
                        // the first long press shows it too, it starts the count
                        onLongPress: () {
                          widget.onLongPress(item);
                          toRow();
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// a fling already holds new thumbnails back, a scrollbar drag jumps so it needs this.
/// else every cell it passes asks the gallery for a thumbnail, and the ones it stops on wait behind them.
class _DeferPhysics extends ScrollPhysics {
  final ValueListenable<bool> moving;

  const _DeferPhysics(this.moving, {super.parent});

  @override
  _DeferPhysics applyTo(ScrollPhysics? ancestor) => _DeferPhysics(moving, parent: buildParent(ancestor));

  @override
  bool recommendDeferredLoading(double velocity, ScrollMetrics metrics, BuildContext context) =>
      moving.value || super.recommendDeferredLoading(velocity, metrics, context);
}
