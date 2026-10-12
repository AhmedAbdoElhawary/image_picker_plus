import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';

enum CameraFailure { noCamera, denied, noMicrophone }

class CameraException implements Exception {
  final CameraFailure failure;

  const CameraException(this.failure);

  @override
  String toString() => "CameraException($failure)";
}

abstract class CameraService {
  /// returns the camera count, throws [CameraException].
  Future<int> init({bool front = false});

  /// false when the microphone was denied and videos have no sound.
  bool get hasMicrophone;

  /// width / height of the camera image held wide.
  double get aspectRatio;

  /// the camera image, tall or wide by [portrait]. [child] covers it at the same size.
  Widget preview({required bool portrait, Widget? child});

  Future<void> switchCamera();

  Future<void> setFlash(bool on);

  /// focuses and sets the exposure at [point], 0 to 1 from the preview's top left.
  Future<void> focus(Offset point);

  bool get hasFlash;

  double get minZoom;

  /// capped at 10, past that a phone's digital zoom is mostly noise.
  double get maxZoom;

  /// clamped to the range, never throws for a level outside it.
  Future<void> setZoom(double level);

  Future<PickedItem> takePhoto();

  Future<void> startVideo();

  Future<PickedItem> stopVideo();

  Future<void> dispose();
}
