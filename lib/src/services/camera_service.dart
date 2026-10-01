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

  /// width / height of the preview in portrait.
  double get aspectRatio;

  Widget preview();

  Future<void> switchCamera();

  Future<void> setFlash(bool on);

  bool get hasFlash;

  Future<PickedItem> takePhoto();

  Future<void> startVideo();

  Future<PickedItem> stopVideo();

  Future<void> dispose();
}
