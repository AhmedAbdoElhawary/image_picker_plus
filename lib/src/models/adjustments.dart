/// the edit page's sliders for one image, each -1..1 with 0 as no change.
class Adjustments {
  /// lighter above 0, darker below.
  final double brightness;

  /// stronger above 0, flat grey at -1.
  final double contrast;

  /// stronger colours above 0, grey at -1.
  final double saturation;

  /// warmer (more red) above 0, cooler (more blue) below.
  final double warmth;

  /// all at 0 by default, each -1..1.
  const Adjustments({this.brightness = 0, this.contrast = 0, this.saturation = 0, this.warmth = 0});

  /// every slider at 0.
  static const Adjustments neutral = Adjustments();

  /// true when every slider is at 0.
  bool get isNeutral => this == neutral;

  /// a copy with the given sliders changed.
  Adjustments copyWith({double? brightness, double? contrast, double? saturation, double? warmth}) =>
      Adjustments(
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        warmth: warmth ?? this.warmth,
      );

  /// all four as one 5x4 matrix for `ColorFilter.matrix`, applied brightness first.
  List<double> get matrix {
    final c = contrast < 0 ? 1 + contrast : 1 + 2 * contrast;
    final s = 1 + saturation;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    // brightness then contrast around the middle grey, in one scale and offset
    final result = _multiply([
      lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ], _scale(c, 64 * brightness * c + 128 * (1 - c)));
    return _multiply([
      1, 0, 0, 0, 24 * warmth, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, -24 * warmth, //
      0, 0, 0, 1, 0, //
    ], result);
  }

  @override
  bool operator ==(Object other) =>
      other is Adjustments &&
      other.brightness == brightness &&
      other.contrast == contrast &&
      other.saturation == saturation &&
      other.warmth == warmth;

  @override
  int get hashCode => Object.hash(brightness, contrast, saturation, warmth);

  static List<double> _scale(double scale, double offset) => [
    scale, 0, 0, 0, offset, //
    0, scale, 0, 0, offset, //
    0, 0, scale, 0, offset, //
    0, 0, 0, 1, 0, //
  ];
}

/// [filter] first, then [adjustments] on top, as one matrix for the preview and the export.
List<double> composeMatrix(List<double> filter, Adjustments adjustments) =>
    adjustments.isNeutral ? filter : _multiply(adjustments.matrix, filter);

/// [a] after [b], both 5x4 read as 5x5 with a last row of 0 0 0 0 1.
List<double> _multiply(List<double> a, List<double> b) => [
  for (var row = 0; row < 4; row++)
    for (var col = 0; col < 5; col++)
      a[row * 5] * b[col] +
          a[row * 5 + 1] * b[5 + col] +
          a[row * 5 + 2] * b[10 + col] +
          a[row * 5 + 3] * b[15 + col] +
          (col == 4 ? a[row * 5 + 4] : 0),
];
