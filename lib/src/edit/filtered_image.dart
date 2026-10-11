import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_layer.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';

/// only this rebuilds when the filter or a slider changes, not the crop around it.
class FilteredImage extends StatelessWidget {
  final MediaItem item;
  final ValueNotifier<int>? filter;
  final ValueNotifier<Adjustments>? adjustments;
  final CropController? crop;

  /// the turns and flip when [crop] is left null.
  final CropController? orientation;
  final MarkupController? markup;

  const FilteredImage({
    required this.item,
    required this.filter,
    required this.crop,
    required this.markup,
    this.adjustments,
    this.orientation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final image = PreviewImage(item: item, fit: BoxFit.fill, crop: crop, orientation: orientation);
    final filter = this.filter;
    final adjustments = this.adjustments;
    final filtered = filter == null && adjustments == null
        ? image
        : ListenableBuilder(
            listenable: Listenable.merge([filter, adjustments]),
            builder: (context, image) => ColorFiltered(
              colorFilter: ColorFilter.matrix(
                composeMatrix(
                  filterMatrix(PickerScope.of(context).settings.filters, filter?.value ?? 0),
                  adjustments?.value ?? Adjustments.neutral,
                ),
              ),
              child: image,
            ),
            child: image,
          );
    final markup = this.markup;
    if (markup == null) return filtered;
    // beside the filter, not under it, so it keeps its own colors
    return Stack(
      fit: StackFit.expand,
      children: [
        filtered,
        MarkupLayer(controller: markup),
      ],
    );
  }
}
