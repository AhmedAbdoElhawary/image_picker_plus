import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

/// the crop of one image, as a rect normalized to 0..1 of the image as shown, after its turns and flip.
class CropController extends ValueNotifier<Rect> {
  /// width / height of the image file in pixels, before any turn.
  final double sourceAspect;
  CropRatio _ratio;
  int _turns;
  bool _flipped;

  /// after a rotate or a flip, with the shown aspect before it, so the markup can follow.
  void Function(bool flip, double aspectBefore)? onOrient;

  /// the crop can't get smaller than this part of its biggest size.
  static const double minScale = 0.2;

  CropController({required double imageAspect, required this._ratio, int turns = 0, this._flipped = false})
    : sourceAspect = imageAspect,
      _turns = turns % 4,
      super(EditState.full) {
    value = _fit(const Offset(0.5, 0.5), 1);
  }

  CropRatio get ratio => _ratio;

  /// quarter turns counter clockwise, 0..3.
  int get turns => _turns;

  /// mirrored left to right, before the turns.
  bool get flipped => _flipped;

  /// width / height of the image as shown.
  double get imageAspect => _turns.isOdd ? 1 / sourceAspect : sourceAspect;

  /// width / height of the crop in pixels.
  double get aspect => _ratio.ratio ?? imageAspect;

  bool get edited => EditState(cropRect: value, turns: _turns, flipped: _flipped).edited;

  /// how much the crop is zoomed in, 1 is the biggest crop.
  double get zoom => _maxSize.width / value.width;

  set ratio(CropRatio next) {
    if (next == _ratio) return;
    _ratio = next;
    value = _fit(value.center, 1);
  }

  /// a quarter turn counter clockwise. the crop turns with the image when it still has its ratio,
  /// else it's the biggest centred one.
  void rotate() {
    final before = imageAspect;
    final rect = value;
    _turns = (_turns + 1) % 4;
    final turned = Rect.fromLTWH(rect.top, 1 - rect.right, rect.height, rect.width);
    final keeps = (turned.width / turned.height * imageAspect - aspect).abs() < 0.01;
    _set(keeps ? _clamp(turned) : _fit(const Offset(0.5, 0.5), 1));
    onOrient?.call(false, before);
  }

  /// mirrors what's shown left to right.
  void flip() {
    final before = imageAspect;
    // a flip after turns is the flip first and the turns the other way
    _flipped = !_flipped;
    _turns = (4 - _turns) % 4;
    _set(Rect.fromLTRB(1 - value.right, value.top, 1 - value.left, value.bottom));
    onOrient?.call(true, before);
  }

  /// the turns and flip changed even when the rect didn't, so listeners always hear it.
  void _set(Rect rect) {
    if (rect == value) {
      notifyListeners();
    } else {
      value = rect;
    }
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
