import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

/// one picked image or video, in the order the user left them.
class PickedItem {
  /// the original file, or the edited jpeg.
  final XFile file;

  /// image or video.
  final MediaType type;

  /// of [file], in pixels.
  final int width;

  /// of [file], in pixels.
  final int height;

  /// true when cropped or filtered, false for an image only re-encoded for a limit.
  final bool edited;

  /// the gallery id, null for camera photos and system picker files.
  final String? id;

  /// the untouched source, the same as [file] when it wasn't re-encoded.
  final XFile original;

  /// null for videos.
  final EditState? edit;

  /// still over OutputOptions.maxBytes after every attempt.
  final bool overLimit;

  /// [original] is [file] when not given.
  const PickedItem({
    required this.file,
    required this.type,
    required this.width,
    required this.height,
    required this.edited,
    this.id,
    XFile? original,
    this.edit,
    this.overLimit = false,
  }) : original = original ?? file;

  /// a copy with the given parts changed.
  PickedItem copyWith({bool? edited, String? id, XFile? original, EditState? edit}) => PickedItem(
    file: file,
    type: type,
    width: width,
    height: height,
    edited: edited ?? this.edited,
    id: id ?? this.id,
    original: original ?? this.original,
    edit: edit ?? this.edit,
    overLimit: overLimit,
  );

  /// plain json types only, so jsonEncode works on it as is.
  Map<String, Object?> toMap() {
    final edit = this.edit;
    return {
      "v": 1,
      if (id != null) "id": id,
      "file": file.path,
      if (!identical(original, file)) "original": original.path,
      "type": type == MediaType.video ? "video" : "image",
      "width": width,
      "height": height,
      "edited": edited,
      "overLimit": overLimit,
      if (edit != null) "edit": edit.toMap(),
    };
  }

  /// a missing key gets its default, so a map from an older version still loads.
  factory PickedItem.fromMap(Map<String, Object?> map) {
    final file = XFile(map["file"]! as String);
    final original = map["original"];
    final type = map["type"] == "video" ? MediaType.video : MediaType.image;
    final edit = map["edit"];
    final width = map["width"];
    final height = map["height"];
    return PickedItem(
      file: file,
      type: type,
      width: width is int ? width : 0,
      height: height is int ? height : 0,
      edited: map["edited"] == true,
      id: map["id"] as String?,
      original: original is String ? XFile(original) : null,
      edit: type == MediaType.video
          ? null
          : (edit is Map ? EditState.fromMap(edit.cast<String, Object?>()) : const EditState()),
      overLimit: map["overLimit"] == true,
    );
  }
}
