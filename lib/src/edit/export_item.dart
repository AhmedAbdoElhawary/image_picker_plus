import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';

/// every way out of the picker ends here, so the output limits hold for unedited images too.
/// null when the gallery has no file for it anymore.
Future<PickedItem?> exportItem({
  required PickerServices services,
  required OutputOptions output,
  required MediaItem item,
  EditState? state,
  String? cacheKey,
  List<ImageProvider> stickers = const [],
}) async {
  final path = item.path;
  final id = path == null ? item.id : null;
  final edit = item.isVideo ? null : state ?? const EditState();
  final edited = edit != null && edit.edited;
  final XFile? original;
  XFile? source;
  if (path != null) {
    original = source = XFile(path, name: item.name);
  } else if (edited) {
    // ios gives a jpeg of a heic for editing, the original stays the heic
    final files = await Future.wait([
      services.gallery!.file(item),
      services.gallery!.file(item, editable: true),
    ]);
    original = files[0] ?? files[1];
    source = files[1] ?? files[0];
  } else {
    original = await services.gallery!.file(item);
  }
  if (original == null) return null;

  final untouched = PickedItem(
    file: original,
    type: item.type,
    width: item.width,
    height: item.height,
    edited: false,
    id: id,
    edit: edit,
  );
  if (edit == null) return untouched;
  if (!edited && !await _overLimits(original, item, output)) return untouched;

  source ??= path == null ? await services.gallery!.file(item, editable: true) ?? original : original;
  final picked = await services.image.export(
    source,
    edit,
    filters[edit.filterIndex],
    output,
    cacheKey: edited ? cacheKey : null,
    stickers: stickers,
  );
  return picked.copyWith(edited: edited, id: id, original: original, edit: edit);
}

Future<bool> _overLimits(XFile file, MediaItem item, OutputOptions output) async {
  if (!output.hasLimits) return false;
  final maxWidth = output.maxWidth;
  final maxHeight = output.maxHeight;
  final maxBytes = output.maxBytes;
  if (maxWidth != null && item.width > maxWidth) return true;
  if (maxHeight != null && item.height > maxHeight) return true;
  return maxBytes != null && await file.length() > maxBytes;
}
