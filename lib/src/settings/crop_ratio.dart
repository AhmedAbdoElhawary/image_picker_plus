/// a width to height ratio the crop can lock to.
class CropRatio {
  /// the first number, 4 in 4:5.
  final double width;

  /// the second number, 5 in 4:5.
  final double height;

  /// both above 0.
  const CropRatio(this.width, this.height) : assert(width > 0 && height > 0);

  const CropRatio._original() : width = 0, height = 0;

  /// keeps the image's own ratio.
  static const CropRatio original = CropRatio._original();

  /// 1:1.
  static const CropRatio square = CropRatio(1, 1);

  /// 4:5.
  static const CropRatio portrait = CropRatio(4, 5);

  /// 16:9.
  static const CropRatio landscape = CropRatio(16, 9);

  /// every shipped ratio, the default.
  static const List<CropRatio> all = [original, square, portrait, landscape];

  /// null for [original], since it depends on the image.
  double? get ratio => width == 0 ? null : width / height;

  @override
  bool operator ==(Object other) => other is CropRatio && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => ratio == null ? "original" : "${_trim(width)}:${_trim(height)}";

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
