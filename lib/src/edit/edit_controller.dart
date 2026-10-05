import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/image_service.dart';
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
  final ValueNotifier<MediaItem> current;
  final ValueNotifier<bool> exporting = ValueNotifier(false);

  EditController({
    required this.services,
    required this.output,
    required List<MediaItem> items,
    MediaItem? initial,
    this.crops = const {},
    this.filterIndexes = const {},
  }) : items = ValueNotifier(items),
       current = ValueNotifier(initial ?? items.first);

  /// null for videos.
  EditState? stateOf(MediaItem item) {
    if (item.isVideo) return null;
    final crop = crops[item.id];
    return EditState(
      cropRect: crop?.value ?? EditState.full,
      ratio: crop?.ratio,
      filterIndex: filterIndexes[item.id]?.value ?? 0,
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

  /// null when the gallery has no file for it anymore.
  Future<PickedItem?> _export(MediaItem item) async {
    final path = item.path;
    final state = stateOf(item);
    final edited = state != null && state.edited;
    final file = path != null ? XFile(path) : await services.gallery!.file(item, editable: edited);
    if (file == null) return null;
    if (state == null || !edited) {
      return PickedItem(file: file, type: item.type, width: item.width, height: item.height, edited: false);
    }
    return services.image.export(
      file,
      state,
      filters[state.filterIndex],
      output,
      cacheKey: _cacheKey(item, state),
    );
  }

  String _cacheKey(MediaItem item, EditState state) {
    final rect = state.cropRect;
    final crop = [rect.left, rect.top, rect.width, rect.height].map((v) => v.toStringAsFixed(4)).join(",");
    return "edit:${item.id}:${item.modified.millisecondsSinceEpoch}:$crop:${state.filterIndex}"
        ":${output.quality}:${output.maxWidth}x${output.maxHeight}";
  }

  void dispose() {
    items.dispose();
    current.dispose();
    exporting.dispose();
  }
}
