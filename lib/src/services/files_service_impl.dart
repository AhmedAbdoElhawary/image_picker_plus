import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/services/files_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class FilesServiceImpl implements FilesService {
  static const List<String> imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif"];
  static const List<String> videoExtensions = ["mp4", "mov", "m4v", "webm", "mkv", "avi"];

  @override
  Future<List<XFile>> open({required bool multi, required MediaType type}) async {
    final images = type != MediaType.video;
    final videos = type != MediaType.image;
    // every field is set, each platform reads a different one and throws when its own is missing
    final group = XTypeGroup(
      extensions: [if (images) ...imageExtensions, if (videos) ...videoExtensions],
      mimeTypes: [if (images) "image/*", if (videos) "video/*"],
      uniformTypeIdentifiers: [if (images) "public.image", if (videos) "public.movie"],
      webWildCards: [if (images) "image/*", if (videos) "video/*"],
    );
    if (multi) return openFiles(acceptedTypeGroups: [group]);
    final file = await openFile(acceptedTypeGroups: [group]);
    return file == null ? const [] : [file];
  }

  @override
  Future<MediaItem?> read(XFile file) async {
    try {
      final type = isVideo(file) ? MediaType.video : MediaType.image;
      var width = 0;
      var height = 0;
      if (type == MediaType.image) {
        final codec = await ui.instantiateImageCodecWithSize(
          await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes()),
          getTargetSize: (intrinsicWidth, intrinsicHeight) {
            width = intrinsicWidth;
            height = intrinsicHeight;
            // only the size is needed, so the decode is as small as it gets
            return const ui.TargetImageSize(width: 1, height: 1);
          },
        );
        codec.dispose();
      }
      return MediaItem(
        id: file.path,
        path: file.path,
        name: file.name,
        type: type,
        width: width,
        height: height,
        modified: await file.lastModified(),
      );
    } catch (_) {
      return null;
    }
  }

  static bool isVideo(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) return mime.startsWith("video/");
    final name = file.name.isNotEmpty ? file.name : file.path;
    return videoExtensions.contains(name.split(".").last.toLowerCase());
  }
}
