import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';

/// what the picker put in the image cache, it all goes when the picker closes.
final Set<ImageProvider> _loaded = {};

/// the thumbnail of a gallery item, or the file itself for a photo just taken.
/// [gallery] is only used for gallery items, which have no path.
ImageProvider mediaImage(MediaItem item, int size, {required GalleryService? gallery}) {
  final path = item.path;
  // short side at size like the gallery thumbnail, so a cover fit is never blurry
  if (path != null) {
    final image = item.width >= item.height
        ? ResizeImage(fileImage(path), height: size)
        : ResizeImage(fileImage(path), width: size);
    _loaded.add(image);
    return image;
  }
  return AssetThumbnail(item, size, gallery: gallery!);
}

/// the picker closed, the app gets the memory of every image it showed back.
void evictMediaImages() {
  for (final image in _loaded) {
    image.evict();
  }
  _loaded.clear();
}

class AssetThumbnail extends ImageProvider<AssetThumbnail> {
  final MediaItem item;
  final int size;
  final GalleryService gallery;

  const AssetThumbnail(this.item, this.size, {required this.gallery});

  @override
  Future<AssetThumbnail> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(AssetThumbnail key, ImageDecoderCallback decode) {
    _loaded.add(key);
    return _ThumbnailCompleter(_load(decode));
  }

  Future<ImageInfo> _load(ImageDecoderCallback decode) async {
    final bytes = await gallery.thumbnail(item, size);
    if (bytes == null || bytes.isEmpty) throw StateError("no thumbnail for ${item.id}");
    final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) =>
      other is AssetThumbnail &&
      other.item.id == item.id &&
      other.item.modified == item.modified &&
      other.size == size;

  @override
  int get hashCode => Object.hash(item.id, item.modified, size);
}

/// like [OneFrameImageStreamCompleter], but an image landing after the stream is gone is dropped, not thrown on.
/// a cell scrolling away after a cache eviction or a memory clear leaves it gone.
class _ThumbnailCompleter extends ImageStreamCompleter {
  bool _disposed = false;

  _ThumbnailCompleter(Future<ImageInfo> image) {
    image.then<void>(
      (info) => _disposed ? info.dispose() : setImage(info),
      onError: (Object error, StackTrace stack) {
        if (_disposed) return;
        reportError(
          context: ErrorDescription("loading a gallery thumbnail"),
          exception: error,
          stack: stack,
          silent: true,
        );
      },
    );
  }

  @override
  void onDisposed() {
    _disposed = true;
    super.onDisposed();
  }
}
