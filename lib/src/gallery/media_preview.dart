import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_layer.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/gallery/ratio_button.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/select_button.dart';
import 'package:image_picker_plus/src/gallery/video_preview.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

class MediaPreview extends StatelessWidget {
  final GalleryController controller;

  const MediaPreview({required this.controller, super.key});

  /// used when `resizePreview` is off.
  static const int imageSize = 1080;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final preview = ColoredBox(
      color: scope.theme.scrim,
      // the selection too, a shown item that gets deselected loses its crop
      child: Selector<(MediaItem?, CropController?, MarkupController?)>(
        listenable: Listenable.merge([controller.preview, controller.selection]),
        select: () {
          final item = controller.preview.value;
          return (item, controller.crops[item?.id], controller.markups[item?.id]);
        },
        builder: (context, shown, _) {
          final (item, crop, markup) = shown;
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
                        image: markup == null
                            ? PreviewImage(item: item, fit: BoxFit.fill, crop: crop)
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  PreviewImage(item: item, fit: BoxFit.fill, crop: crop),
                                  MarkupLayer(controller: markup),
                                ],
                              ),
                      ),
                      if (scope.settings.cropRatios.length > 1)
                        PositionedDirectional(
                          start: PickerLayout.padding,
                          bottom: PickerLayout.ratioButtonBottomPadding,
                          child: RatioButton(controller: crop),
                        ),
                    ],
                  )
                : PreviewImage(key: ObjectKey(item), item: item),
          );
        },
      ),
    );
    if (!scope.settings.multi) return preview;
    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        PositionedDirectional(
          end: PickerLayout.padding,
          bottom: PickerLayout.ratioButtonBottomPadding,
          child: SelectButton(controller: controller),
        ),
      ],
    );
  }
}

class PreviewImage extends StatelessWidget {
  final MediaItem item;
  final BoxFit fit;

  /// set inside a crop view, it lays the image out bigger while zoomed in.
  final CropController? crop;

  /// the turns and flip to show the image with, [crop] when null.
  final CropController? orientation;

  const PreviewImage({required this.item, this.fit = BoxFit.contain, this.crop, this.orientation, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final orientation = this.orientation ?? crop;
    final image = LayoutBuilder(
      builder: (context, constraints) {
        final size = scope.settings.resizePreview
            ? _size(constraints.biggest / (crop?.zoom ?? 1), MediaQuery.devicePixelRatioOf(context))
            : MediaPreview.imageSize;
        return Image(
          image: mediaImage(item, size, gallery: scope.services.gallery),
          fit: fit,
          gaplessPlayback: true,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stack) =>
              Center(child: Icon(Icons.broken_image_outlined, color: scope.theme.onSurfaceMuted)),
        );
      },
    );
    if (orientation == null) return image;
    // the box is the image as shown, the file is laid out turned back inside it
    return Selector<(int, bool)>(
      listenable: orientation,
      select: () => (orientation.turns, orientation.flipped),
      builder: (context, shown, image) => RotatedBox(
        quarterTurns: -shown.$1,
        child: Transform.flip(flipX: shown.$2, child: image),
      ),
      child: image,
    );
  }

  /// pixels of the image's short side when it fits in [box] zoomed out.
  int _size(Size box, double pixelRatio) {
    final aspect = item.width == 0 || item.height == 0 ? 1.0 : item.width / item.height;
    final width = min(box.width, box.height * aspect);
    // round not ceil, the zoom division is a hair off and would load it again while pinching
    return max(1, (min(width, width / aspect) * pixelRatio).round());
  }
}
