import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/orientation.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

/// the edits of each image in one picker session, by image id. the edit page shares them,
/// so going back shows what was changed there. an image has only what the settings turn on.
class ImageEdits {
  final Map<String, CropController> crops = {};
  final Map<String, ValueNotifier<int>> filterIndexes = {};
  final Map<String, MarkupController> markups = {};
  final Map<String, ValueNotifier<Adjustments>> adjustments = {};

  /// makes the missing edits [settings] turn on for each image in [items], videos get none.
  /// a new crop starts at [ratio], the first of the settings when null.
  void prepare(Iterable<MediaItem> items, PickerSettings settings, {CropRatio? ratio}) {
    for (final item in items) {
      if (item.isVideo) continue;
      if (settings.cropRatios.isNotEmpty && !crops.containsKey(item.id)) {
        final aspect = item.height == 0 ? 1.0 : item.width / item.height;
        put(
          item.id,
          crop: CropController(imageAspect: aspect, ratio: ratio ?? settings.cropRatios.first),
        );
      }
      if (settings.filters.isNotEmpty) filterIndexes.putIfAbsent(item.id, () => ValueNotifier(0));
      if (settings.adjustments) adjustments.putIfAbsent(item.id, () => ValueNotifier(Adjustments.neutral));
      if (settings.markup.enabled) markups.putIfAbsent(item.id, MarkupController.new);
    }
  }

  /// adds edits made somewhere else for the image [id].
  void put(
    String id, {
    CropController? crop,
    ValueNotifier<int>? filterIndex,
    MarkupController? markup,
    ValueNotifier<Adjustments>? adjustment,
  }) {
    if (crop != null) {
      crops[id] = crop;
      // looked up on each move, the markup can be made after the crop
      crop.onOrient = (flip, aspectBefore) =>
          markups[id]?.transform(flip ? flipItem : (item) => rotateItem(item, aspectBefore));
    }
    if (filterIndex != null) filterIndexes[id] = filterIndex;
    if (markup != null) markups[id] = markup;
    if (adjustment != null) adjustments[id] = adjustment;
  }

  /// takes over everything in [other], which is left empty and not disposed.
  void addAll(ImageEdits other) {
    for (final id in {
      ...other.crops.keys,
      ...other.filterIndexes.keys,
      ...other.markups.keys,
      ...other.adjustments.keys,
    }) {
      put(
        id,
        crop: other.crops[id],
        filterIndex: other.filterIndexes[id],
        markup: other.markups[id],
        adjustment: other.adjustments[id],
      );
    }
    for (final map in [other.crops, other.filterIndexes, other.markups, other.adjustments]) {
      map.clear();
    }
  }

  /// disposes and drops the edits of every image not in [ids].
  void keep(Set<String> ids) {
    for (final map in <Map<String, ChangeNotifier>>[crops, filterIndexes, markups, adjustments]) {
      map.removeWhere((id, notifier) {
        if (ids.contains(id)) return false;
        notifier.dispose();
        return true;
      });
    }
  }

  void dispose() => keep(const {});
}
