import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

class GalleryCell extends StatelessWidget {
  final MediaItem item;
  final GalleryController controller;

  /// thumbnail size in pixels.
  final int size;
  final VoidCallback onTap;

  const GalleryCell({required this.item, required this.controller, required this.size, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final durations = PickerDurations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Selector<int>(
        listenable: controller.selection,
        select: () => controller.orderOf(item),
        builder: (context, order) => Semantics(
          button: true,
          selected: order > 0,
          label: item.isVideo ? scope.texts.video : scope.texts.photo,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: scope.theme.surface,
                child: AnimatedScale(
                  scale: order > 0 ? 0.92 : 1,
                  duration: durations.short,
                  child: Image(
                    image: AssetThumbnail(item, size, gallery: scope.services.gallery, cache: scope.services.cache),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    frameBuilder: (context, child, frame, sync) => frame == null && !sync ? const LoadingBox() : child,
                    errorBuilder: (context, error, stack) =>
                        Icon(Icons.broken_image_outlined, color: scope.theme.onSurfaceMuted),
                  ),
                ),
              ),
              _PreviewDim(controller: controller, item: item),
              if (item.isVideo) _Duration(item.duration),
              if (controller.settings.multi) _OrderBadge(order),
            ],
          ),
        ),
      ),
    );
  }
}

/// marks the item shown in the preview.
class _PreviewDim extends StatelessWidget {
  final GalleryController controller;
  final MediaItem item;

  const _PreviewDim({required this.controller, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return Selector<bool>(
      listenable: controller.preview,
      select: () => controller.preview.value == item,
      builder: (context, shown) => AnimatedOpacity(
        opacity: shown ? 0.45 : 0,
        duration: PickerDurations.of(context).short,
        child: ColoredBox(color: theme.background),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int order;

  const _OrderBadge(this.order);

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final selected = order > 0;
    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(6),
        child: AnimatedSwitcher(
          duration: PickerDurations.of(context).short,
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Container(
            key: ValueKey(order),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? theme.accent : theme.scrim.withValues(alpha: 0.2),
              border: Border.all(color: theme.onAccent, width: 1.5),
            ),
            child: selected
                ? Text(
                    "$order",
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(color: theme.onAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _Duration extends StatelessWidget {
  final Duration duration;

  const _Duration(this.duration);

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, "0");
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(6),
        child: Text(
          "$minutes:$seconds",
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: theme.onAccent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: theme.scrim, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
