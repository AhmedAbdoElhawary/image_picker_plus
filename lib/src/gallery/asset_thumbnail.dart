import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/services/cache_service.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';

/// the thumbnail of a gallery item, or the file itself for a photo just taken.
/// [gallery] is only used for gallery items, which have no path.
ImageProvider mediaImage(MediaItem item, int size, {required GalleryService? gallery, CacheService? cache}) {
  final path = item.path;
  // short side at size like the gallery thumbnail, so a cover fit is never blurry
  if (path != null) {
    return item.width >= item.height
        ? ResizeImage(fileImage(path), height: size)
        : ResizeImage(fileImage(path), width: size);
  }
  return AssetThumbnail(item, size, gallery: gallery!, cache: cache);
}

class AssetThumbnail extends ImageProvider<AssetThumbnail> {
  final MediaItem item;
  final int size;
  final GalleryService gallery;

  /// null when caching is off.
  final CacheService? cache;

  const AssetThumbnail(this.item, this.size, {required this.gallery, this.cache});

  String get cacheKey => "thumb:${item.id}:${item.modified.millisecondsSinceEpoch}:$size";

  @override
  Future<AssetThumbnail> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(AssetThumbnail key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await loadBytes();
    if (bytes == null || bytes.isEmpty) throw StateError("no thumbnail for ${item.id}");
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @visibleForTesting
  Future<Uint8List?> loadBytes() async {
    final cached = await cache?.read(cacheKey);
    if (cached != null) return cached;
    final bytes = await gallery.thumbnail(item, size);
    if (bytes != null) await cache?.write(cacheKey, bytes);
    return bytes;
  }

  @override
  bool operator ==(Object other) =>
      other is AssetThumbnail && other.item.id == item.id && other.item.modified == item.modified && other.size == size;

  @override
  int get hashCode => Object.hash(item.id, item.modified, size);
}
