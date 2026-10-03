import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/services/image_service.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

/// the crop of one image, as a rect normalized to 0..1 of the image.
class CropController extends ValueNotifier<Rect> {
  /// width / height of the image in pixels.
  final double imageAspect;
  CropRatio _ratio;

  /// the crop can't get smaller than this part of its biggest size.
  static const double minScale = 0.2;

  CropController({required this.imageAspect, required this._ratio}) : super(EditState.full) {
    value = _fit(const Offset(0.5, 0.5), 1);
  }

  CropRatio get ratio => _ratio;

  /// width / height of the crop in pixels.
  double get aspect => _ratio.ratio ?? imageAspect;

  bool get edited => EditState(cropRect: value).edited;

  /// how much the crop is zoomed in, 1 is the biggest crop.
  double get zoom => _maxSize.width / value.width;

  set ratio(CropRatio next) {
    if (next == _ratio) return;
    _ratio = next;
    value = _fit(value.center, 1);
  }

  /// [delta] is in parts of the image, moving the crop over it.
  void pan(Offset delta) => value = _clamp(value.shift(delta));

  /// [focal] stays in place, it's normalized like the rect.
  void zoomTo(double next, {Offset? focal}) {
    final scale = next.clamp(1.0, 1 / minScale);
    final center = focal ?? value.center;
    final size = _maxSize / scale;
    final fx = (center.dx - value.left) / value.width;
    final fy = (center.dy - value.top) / value.height;
    final rect = Rect.fromLTWH(
      center.dx - size.width * fx,
      center.dy - size.height * fy,
      size.width,
      size.height,
    );
    value = _clamp(rect);
  }

  /// the biggest normalized size with the crop aspect.
  Size get _maxSize {
    final relative = aspect / imageAspect;
    return relative >= 1 ? Size(1, 1 / relative) : Size(relative, 1);
  }

  Rect _fit(Offset center, double scale) {
    final size = _maxSize / scale;
    return _clamp(Rect.fromCenter(center: center, width: size.width, height: size.height));
  }

  Rect _clamp(Rect rect) {
    final width = min(rect.width, 1.0);
    final height = min(rect.height, 1.0);
    final left = rect.left.clamp(0.0, 1 - width);
    final top = rect.top.clamp(0.0, 1 - height);
    return Rect.fromLTWH(left, top, width, height);
  }
}
