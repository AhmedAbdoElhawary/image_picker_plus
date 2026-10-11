import 'dart:ui';

/// the file type of edited and re-encoded images.
enum OutputFormat {
  /// smaller, no transparency.
  jpeg,

  /// keeps transparency, bigger, [OutputOptions.quality] does nothing.
  png,
}

/// how edited images are saved.
class OutputOptions {
  /// jpeg is the default.
  final OutputFormat format;

  /// jpeg quality 1 to 100, 90 by default. png ignores it.
  final int quality;

  /// for every image, an unedited one over it comes back scaled with its original attached.
  final int? maxWidth;

  /// for every image, an unedited one over it comes back scaled with its original attached.
  final int? maxHeight;

  /// images only, videos are never re-encoded. png gets under it by scaling down only.
  final int? maxBytes;

  /// jpeg at 90, no size limits by default.
  const OutputOptions({
    this.format = OutputFormat.jpeg,
    this.quality = 90,
    this.maxWidth,
    this.maxHeight,
    this.maxBytes,
  }) : assert(quality >= 1 && quality <= 100, "quality is 1 to 100"),
       assert(maxWidth == null || maxWidth > 0, "maxWidth is > 0 when set"),
       assert(maxHeight == null || maxHeight > 0, "maxHeight is > 0 when set"),
       assert(maxBytes == null || maxBytes > 0, "maxBytes is > 0 when set");

  /// above any phone screen and below the gpu texture limit of older devices.
  static const int safeMaxSide = 4096;

  /// below this jpeg blocks show, scaling down looks better.
  static const int qualityFloor = 50;

  /// what transparent parts become in a jpeg. it's the saved file's look, not the picker's.
  static const Color jpegBackground = Color(0xFFFFFFFF);

  /// true when any size limit is set.
  bool get hasLimits => maxWidth != null || maxHeight != null || maxBytes != null;
}
