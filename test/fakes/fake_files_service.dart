import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/services/files_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class FakeFilesService implements FilesService {
  /// what the next [open] returns, an empty list is a cancel.
  List<XFile> next;

  /// when set, [open] waits for it, like a system picker the user hasn't closed yet.
  Completer<List<XFile>>? pending;

  /// paths [read] returns null for.
  final Set<String> unreadable;

  int opens = 0;
  bool? lastMulti;
  MediaType? lastType;

  FakeFilesService({List<XFile>? next, Set<String>? unreadable})
    : next = next ?? [],
      unreadable = unreadable ?? {};

  static List<XFile> files(int count, {String extension = "jpg"}) =>
      List.generate(count, (index) => XFile("/picked/$index.$extension", name: "$index.$extension"));

  @override
  Future<List<XFile>> open({required bool multi, required MediaType type}) {
    opens++;
    lastMulti = multi;
    lastType = type;
    final pending = this.pending;
    if (pending != null) {
      this.pending = null;
      return pending.future;
    }
    return Future.value(next);
  }

  @override
  Future<MediaItem?> read(XFile file) async {
    if (unreadable.contains(file.path)) return null;
    final video = file.path.endsWith(".mp4");
    return MediaItem(
      id: file.path,
      path: file.path,
      name: file.name,
      type: video ? MediaType.video : MediaType.image,
      width: video ? 0 : 400,
      height: video ? 0 : 300,
      modified: DateTime(2026),
    );
  }
}
