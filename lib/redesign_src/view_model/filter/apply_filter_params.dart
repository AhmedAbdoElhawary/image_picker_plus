import 'package:image/image.dart';

class ApplyFilterParams {
  final Image img;
  final List<double> colorMatrix;
  final double brightness;
  final double contrast;
  final double saturation;
  final List<double>? defaultMatrix;
  final bool shouldCompress;
  final int? compressQuality;

  // Default matrix
  static const List<double> _defaultMatrix = [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  ApplyFilterParams({
    required this.img,
    required this.colorMatrix,
    this.brightness = 0.627,
    this.contrast = 0.996,
    this.saturation = 1.8,
    this.defaultMatrix = _defaultMatrix,
    this.shouldCompress = false,
    this.compressQuality = 100,
  });
}
