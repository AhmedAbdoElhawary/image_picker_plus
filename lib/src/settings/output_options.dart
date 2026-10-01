class OutputOptions {
  final int quality;
  final int? maxWidth;
  final int? maxHeight;

  const OutputOptions({this.quality = 90, this.maxWidth, this.maxHeight})
    : assert(quality >= 1 && quality <= 100, "quality is 1 to 100"),
      assert(maxWidth == null || maxWidth > 0, "maxWidth is > 0 when set"),
      assert(maxHeight == null || maxHeight > 0, "maxHeight is > 0 when set");

  /// above any phone screen and below the gpu texture limit of older devices.
  static const int safeMaxSide = 4096;
}
