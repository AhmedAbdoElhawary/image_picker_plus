import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:image_picker_plus/src/models/album.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

enum GalleryAccess { full, limited, denied }

abstract class GalleryService {
  Future<GalleryAccess> requestAccess();

  /// the first one is recent (all items).
  Future<List<Album>> albums(MediaType type);

  Future<List<MediaItem>> items(Album album, {required int page, required int size});

  Future<Uint8List?> thumbnail(MediaItem item, int size);

  /// [editable] asks for one the image package can read, ios gives a jpeg of a heic photo then.
  Future<XFile?> file(MediaItem item, {bool editable = false});

  Stream<void> get changes;

  Future<void> openSettings();

  Future<void> manageLimitedAccess();
}
