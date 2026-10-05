import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/filters.dart' as shipped;
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/markup_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

/// the items of an earlier pick, found again so the picker can open with them selected.
class Preselection {
  /// in the order they were picked.
  final List<MediaItem> items;

  /// per item id, only for images that had one.
  final Map<String, EditState> edits;

  /// one or more were gone, of the wrong type, or unreadable.
  final bool skipped;

  const Preselection({this.items = const [], this.edits = const {}, this.skipped = false});

  /// cut to the max before looking anything up, like the system picker does.
  static Future<Preselection> resolve({
    required PickerServices services,
    required PickerSettings settings,
    required List<PickedItem> selected,
  }) async {
    final kept = selected.take(settings.maxSelection).toList();
    assert(() {
      if (kept.length < selected.length) {
        debugPrint(
          "image_picker_plus: ${selected.length} items passed as selected, "
          "only the first ${settings.maxSelection} are kept",
        );
      }
      return true;
    }());
    final items = <MediaItem>[];
    final edits = <String, EditState>{};
    var skipped = false;
    for (final picked in kept) {
      final id = picked.id;
      final gallery = services.gallery;
      // a gallery item can't be found on web and desktop, there's no gallery
      final item = id == null
          ? await services.files.read(picked.original)
          : (gallery == null ? null : await gallery.item(id));
      if (item == null || !_allowed(item.type, settings.mediaType)) {
        skipped = true;
        continue;
      }
      if (items.contains(item)) continue;
      items.add(item);
      final edit = picked.edit;
      if (edit != null && !item.isVideo) edits[item.id] = edit;
    }
    return Preselection(items: items, edits: edits, skipped: skipped);
  }

  /// the crop and filter of each image from its edits, a ratio or filter these settings don't have falls back.
  /// [ratios] are the ones the picker offers here, the first is the fallback, empty means no crop.
  /// markup comes back when it's on.
  (Map<String, CropController>, Map<String, ValueNotifier<int>>, Map<String, MarkupController>) restore({
    required List<CropRatio> ratios,
    required bool filters,
    MarkupOptions markup = const MarkupOptions(),
  }) {
    final crops = <String, CropController>{};
    final filterIndexes = <String, ValueNotifier<int>>{};
    final markups = <String, MarkupController>{};
    for (final item in items) {
      final edit = edits[item.id];
      if (edit == null) continue;
      if (ratios.isNotEmpty) {
        final kept = ratios.contains(edit.ratio);
        final crop = crops[item.id] = CropController(
          imageAspect: item.height == 0 ? 1 : item.width / item.height,
          ratio: kept ? edit.ratio! : ratios.first,
        );
        if (kept) crop.value = edit.cropRect;
      }
      if (filters) {
        final index = edit.filterIndex < shipped.filters.length ? edit.filterIndex : 0;
        filterIndexes[item.id] = ValueNotifier(index);
      }
      if (markup.enabled) {
        markups[item.id] = MarkupController(edit.markup);
      }
    }
    return (crops, filterIndexes, markups);
  }

  static bool _allowed(MediaType type, MediaType allowed) => allowed == MediaType.all || type == allowed;
}
