class OutputOptions {
  final int quality;

  /// for every image, an unedited one over it comes back scaled with its original attached.
  final int? maxWidth;

  /// for every image, an unedited one over it comes back scaled with its original attached.
  final int? maxHeight;

  /// images only, videos are never re-encoded.
  final int? maxBytes;

  const OutputOptions({this.quality = 90, this.maxWidth, this.maxHeight, this.maxBytes})
    : assert(quality >= 1 && quality <= 100, "quality is 1 to 100"),
      assert(maxWidth == null || maxWidth > 0, "maxWidth is > 0 when set"),
      assert(maxHeight == null || maxHeight > 0, "maxHeight is > 0 when set"),
      assert(maxBytes == null || maxBytes > 0, "maxBytes is > 0 when set");

  /// above any phone screen and below the gpu texture limit of older devices.
  static const int safeMaxSide = 4096;

  /// below this jpeg blocks show, scaling down looks better.
  static const int qualityFloor = 50;

  bool get hasLimits => maxWidth != null || maxHeight != null || maxBytes != null;
}
