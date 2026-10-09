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

  /// pixels of the box it covers, the thumbnail is cut to it. null keeps it whole.
  final Size? cover;

  const AssetThumbnail(this.item, this.size, {required this.gallery, this.cache, this.cover});

  String get cacheKey => "thumb:${item.id}:${item.modified.millisecondsSinceEpoch}:$size";

  @override
  Future<AssetThumbnail> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(AssetThumbnail key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_load(decode));

  Future<ImageInfo> _load(ImageDecoderCallback decode) async {
    final bytes = await loadBytes();
    if (bytes == null || bytes.isEmpty) throw StateError("no thumbnail for ${item.id}");
    final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    final cover = this.cover;
    if (cover == null) return ImageInfo(image: image);
    // the sides a cover fit hides would stay decoded in memory for nothing
    final full = Size(image.width.toDouble(), image.height.toDouble());
    final source = Alignment.center.inscribe(
      applyBoxFit(BoxFit.cover, full, cover).source,
      Offset.zero & full,
    );
    final recorder = ui.PictureRecorder();
    final paint = Paint()..filterQuality = FilterQuality.medium;
    Canvas(recorder).drawImageRect(image, source, Offset.zero & cover, paint);
    final picture = recorder.endRecording();
    final cut = await picture.toImage(cover.width.ceil(), cover.height.ceil());
    picture.dispose();
    image.dispose();
    return ImageInfo(image: cut);
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
      other is AssetThumbnail &&
      other.item.id == item.id &&
      other.item.modified == item.modified &&
      other.size == size &&
      other.cover == cover;

  @override
  int get hashCode => Object.hash(item.id, item.modified, size, cover);
}
