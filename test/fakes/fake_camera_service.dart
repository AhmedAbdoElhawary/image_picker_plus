import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class FakeCameraService implements CameraService {
  CameraFailure? failure;
  int cameras;
  bool flash;
  bool mic;

  /// change it between photos to tell them apart.
  String photoPath = "/fake/photo.jpg";

  int initCalls = 0;
  int disposeCalls = 0;
  int switchCalls = 0;
  bool? lastFlash;
  Offset? lastFocus;
  bool recording = false;

  FakeCameraService({this.failure, this.cameras = 2, this.flash = true, this.mic = true});

  @override
  Future<int> init({bool front = false}) async {
    initCalls++;
    if (failure != null) throw CameraException(failure!);
    return cameras;
  }

  @override
  bool get hasMicrophone => mic;

  @override
  double get aspectRatio => 3 / 4;

  @override
  Widget preview() => const SizedBox.expand(key: Key("fake-preview"));

  @override
  Future<void> switchCamera() async => switchCalls++;

  @override
  Future<void> setFlash(bool on) async => lastFlash = on;

  @override
  Future<void> focus(Offset point) async => lastFocus = point;

  @override
  bool get hasFlash => flash;

  @override
  Future<PickedItem> takePhoto() async =>
      PickedItem(file: XFile(photoPath), type: MediaType.image, width: 300, height: 400, edited: false);

  @override
  Future<void> startVideo() async => recording = true;

  @override
  Future<PickedItem> stopVideo() async {
    recording = false;
    return PickedItem(
      file: XFile("/fake/video.mp4"),
      type: MediaType.video,
      width: 0,
      height: 0,
      edited: false,
    );
  }

  @override
  Future<void> dispose() async => disposeCalls++;
}
