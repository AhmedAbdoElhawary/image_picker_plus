import 'package:image_picker_plus/src/settings/picker_settings.dart';

class MediaItem {
  final String id;
  final MediaType type;
  final int width;
  final int height;
  final Duration duration;

  /// part of the cache key, so an edited photo never gets an old thumbnail.
  final DateTime modified;

  /// set for a photo just taken, it isn't in the gallery.
  final String? path;

  /// the file name from the system picker, null for gallery items.
  final String? name;

  const MediaItem({
    required this.id,
    required this.type,
    required this.width,
    required this.height,
    required this.modified,
    this.duration = Duration.zero,
    this.path,
    this.name,
  });

  bool get isVideo => type == MediaType.video;

  @override
  bool operator ==(Object other) => other is MediaItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
