import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/ratio_button.dart';
import 'package:image_picker_plus/src/gallery/video_preview.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

class MediaPreview extends StatelessWidget {
  final GalleryController controller;

  const MediaPreview({required this.controller, super.key});

  static const int imageSize = 1080;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ColoredBox(
      color: scope.theme.surface,
      child: ValueListenableBuilder<MediaItem?>(
        valueListenable: controller.preview,
        builder: (context, item, _) {
          final crop = item == null ? null : controller.crops[item.id];
          return AnimatedSwitcher(
            duration: PickerDurations.of(context).short,
            child: item == null
                ? const LoadingBox()
                : item.isVideo
                ? VideoPreview(key: ObjectKey(item), item: item)
                : crop != null
                ? Stack(
                    key: ObjectKey(crop),
                    children: [
                      CropView(
                        controller: crop,
                        image: PreviewImage(item: item, fit: BoxFit.fill),
                      ),
                      if (scope.settings.cropRatios.length > 1)
                        PositionedDirectional(
                          start: PickerLayout.padding,
                          bottom: PickerLayout.padding,
                          child: RatioButton(controller: crop),
                        ),
                    ],
                  )
                : PreviewImage(key: ObjectKey(item), item: item),
          );
        },
      ),
    );
  }
}

class PreviewImage extends StatelessWidget {
  final MediaItem item;
  final BoxFit fit;

  const PreviewImage({required this.item, this.fit = BoxFit.contain, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Image(
      image: mediaImage(item, MediaPreview.imageSize, gallery: scope.services.gallery, cache: scope.services.cache),
      fit: fit,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) =>
          Center(child: Icon(Icons.broken_image_outlined, color: scope.theme.onSurfaceMuted)),
    );
  }
}
