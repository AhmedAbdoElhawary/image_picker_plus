import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/video_tile.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

/// long press and drag to reorder, tap to edit that item.
class ReorderStrip extends StatelessWidget {
  final EditController controller;

  /// null hides the plus, it also hides at the max.
  final VoidCallback? onAdd;

  const ReorderStrip({required this.controller, this.onAdd, super.key});

  static const double _size = 56;

  /// a mouse drags right away. a phone browser reports android or ios, there a plain drag has to scroll the strip.
  static bool get _desktop => switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return SizedBox(
      height: _size + 16,
      child: ValueListenableBuilder<List<MediaItem>>(
        valueListenable: controller.items,
        builder: (context, items, _) => ReorderableListView.builder(
          // a footer can't be dragged, and nothing can be dropped after it
          footer: onAdd != null && items.length < scope.settings.maxSelection ? _AddTile(onTap: onAdd!) : null,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: PickerLayout.padding, vertical: 8),
          buildDefaultDragHandles: false,
          itemCount: items.length,
          onReorderItem: controller.reorder,
          // the dragged copy is built in the overlay, outside the scope
          proxyDecorator: (child, _, _) => scope.wrap(child),
          itemBuilder: (context, index) => _desktop
              ? ReorderableDragStartListener(
                  key: ValueKey(items[index].id),
                  index: index,
                  child: _Thumb(item: items[index], controller: controller),
                )
              : ReorderableDelayedDragStartListener(
                  key: ValueKey(items[index].id),
                  index: index,
                  child: _Thumb(item: items[index], controller: controller),
                ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Semantics(
      button: true,
      label: scope.texts.add,
      child: Material(
        color: scope.theme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: ReorderStrip._size,
            child: Icon(Icons.add_rounded, color: scope.theme.onSurface, size: 28),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatefulWidget {
  final MediaItem item;
  final EditController controller;

  const _Thumb({required this.item, required this.controller});

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  bool _focused = false;
  bool _hovered = false;

  void _select() => widget.controller.current.value = widget.item;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final item = widget.item;
    final controller = widget.controller;
    final pixels = (ReorderStrip._size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        // closer than the page's enter, so enter here selects instead of done
        shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()},
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _select())},
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        child: GestureDetector(
          onTap: _select,
          child: Selector<bool>(
            listenable: controller.current,
            select: () => controller.current.value == item,
            builder: (context, current, _) => Container(
              width: ReorderStrip._size,
              height: ReorderStrip._size,
              padding: const EdgeInsetsDirectional.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: current || _focused
                      ? scope.theme.accent
                      : (_hovered ? scope.theme.onSurfaceMuted : scope.theme.background),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: item.isVideo && item.path != null
                    ? const VideoTile()
                    : Image(
                        image: mediaImage(item, pixels, gallery: scope.services.gallery, cache: scope.services.cache),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stack) =>
                            Icon(Icons.broken_image_outlined, color: scope.theme.onSurfaceMuted),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
