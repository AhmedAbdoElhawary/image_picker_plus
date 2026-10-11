import 'package:image_picker_plus/src/settings/picker_settings.dart';

/// an image or video in the gallery, from the camera or from the system picker.
class MediaItem {
  /// the gallery id, or the file path when it isn't in the gallery.
  final String id;

  /// image or video.
  final MediaType type;

  /// in pixels.
  final int width;

  /// in pixels.
  final int height;

  /// zero for images.
  final Duration duration;

  /// part of the cache key, so an edited photo never gets an old thumbnail.
  final DateTime modified;

  /// when it was taken, only set for gallery items.
  final DateTime? created;

  /// set for a photo just taken, it isn't in the gallery.
  final String? path;

  /// the file name from the system picker, null for gallery items.
  final String? name;

  /// an item as the gallery or a file reports it.
  const MediaItem({
    required this.id,
    required this.type,
    required this.width,
    required this.height,
    required this.modified,
    this.duration = Duration.zero,
    this.created,
    this.path,
    this.name,
  });

  /// true for a video.
  bool get isVideo => type == MediaType.video;

  @override
  bool operator ==(Object other) => other is MediaItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
