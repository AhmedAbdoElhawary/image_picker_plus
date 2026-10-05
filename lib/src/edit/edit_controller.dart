import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/export_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';

class EditController {
  final PickerServices services;
  final OutputOptions output;

  /// in the order they'll be returned.
  final ValueNotifier<List<MediaItem>> items;

  /// per image id, owned by the page that opened the edit, so its changes stay there on back.
  /// an image has no crop when cropping is off, and no filter when filters are off.
  final Map<String, CropController> crops;
  final Map<String, ValueNotifier<int>> filterIndexes;

  /// per image id like the crops, empty when markup is off.
  final Map<String, MarkupController> markups;

  /// the markup mode on the current image, null when not in it.
  final ValueNotifier<MarkupTool?> tool = ValueNotifier(null);
  final ValueNotifier<MediaItem> current;
  final ValueNotifier<bool> exporting = ValueNotifier(false);

  EditController({
    required this.services,
    required this.output,
    required List<MediaItem> items,
    MediaItem? initial,
    this.crops = const {},
    this.filterIndexes = const {},
    this.markups = const {},
    this.stickers = const [],
  }) : items = ValueNotifier(items),
       current = ValueNotifier(initial ?? items.first) {
    // a mode belongs to one image, moving on leaves it
    current.addListener(() => tool.value = null);
  }

  /// `MarkupOptions.stickers`, for the export.
  final List<ImageProvider> stickers;

  /// null for videos.
  EditState? stateOf(MediaItem item) {
    if (item.isVideo) return null;
    final crop = crops[item.id];
    return EditState(
      cropRect: crop?.value ?? EditState.full,
      ratio: crop?.ratio,
      filterIndex: filterIndexes[item.id]?.value ?? 0,
      markup: markups[item.id]?.value ?? const [],
    );
  }

  void setFilter(int index) => filterIndexes[current.value.id]?.value = index;

  void reorder(int oldIndex, int newIndex) {
    final list = [...items.value];
    list.insert(newIndex, list.removeAt(oldIndex));
    items.value = list;
  }

  /// edited images become jpegs, everything else is the original file.
  Future<List<PickedItem>> export() async {
    exporting.value = true;
    try {
      // the gallery file fetch can be slow too (icloud), so each item runs fully in parallel
      final picked = await Future.wait(items.value.map(_export));
      return picked.nonNulls.toList();
    } finally {
      exporting.value = false;
    }
  }

  Future<PickedItem?> _export(MediaItem item) {
    final state = stateOf(item);
    return exportItem(
      services: services,
      output: output,
      item: item,
      state: state,
      cacheKey: state == null ? null : _cacheKey(item, state),
      stickers: stickers,
    );
  }

  String _cacheKey(MediaItem item, EditState state) {
    final rect = state.cropRect;
    final crop = [rect.left, rect.top, rect.width, rect.height].map((v) => v.toStringAsFixed(4)).join(",");
    return "edit:${item.id}:${item.modified.millisecondsSinceEpoch}:$crop:${state.filterIndex}"
        ":${output.quality}:${output.maxWidth}x${output.maxHeight}:${output.maxBytes}";
  }

  void dispose() {
    items.dispose();
    current.dispose();
    exporting.dispose();
    tool.dispose();
  }
}
