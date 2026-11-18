import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/services/camera_service_impl.dart';

/// records the audio setting each camera opens with, ios kills an app that opens the mic without asking.
class _FakeCameraPlatform extends CameraPlatform {
  final bool micDenied;
  final List<bool> opens = [];

  _FakeCameraPlatform({this.micDenied = false});

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(name: "back", lensDirection: CameraLensDirection.back, sensorOrientation: 90),
  ];

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() => const Stream.empty();

  @override
  Future<int> createCameraWithSettings(CameraDescription cameraDescription, MediaSettings? mediaSettings) async {
    final audio = mediaSettings?.enableAudio ?? false;
    opens.add(audio);
    if (audio && micDenied) throw PlatformException(code: "AudioAccessDenied");
    return opens.length;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(CameraInitializedEvent(cameraId, 1920, 1080, ExposureMode.auto, true, FocusMode.auto, true));

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => StreamController<CameraErrorEvent>().stream;

  @override
  Future<void> initializeCamera(int cameraId, {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {}

  @override
  Future<double> getMinZoomLevel(int cameraId) async => 1;

  @override
  Future<double> getMaxZoomLevel(int cameraId) async => 4;

  @override
  Future<void> dispose(int cameraId) async {}
}

void main() {
  late _FakeCameraPlatform platform;

  void usePlatform(_FakeCameraPlatform fake) => CameraPlatform.instance = platform = fake;

  test("photos only opens the camera without audio, so the mic is never touched", () async {
    usePlatform(_FakeCameraPlatform());
    final camera = CameraServiceImpl(audio: false);
    await camera.init();
    expect(platform.opens, [false]);
    expect(camera.hasMicrophone, isFalse);
  });

  test("videos allowed still opens the camera with audio first", () async {
    usePlatform(_FakeCameraPlatform());
    final camera = CameraServiceImpl();
    await camera.init();
    expect(platform.opens, [true]);
    expect(camera.hasMicrophone, isTrue);
  });

  test("videos allowed with the mic denied opens again without audio", () async {
    usePlatform(_FakeCameraPlatform(micDenied: true));
    final camera = CameraServiceImpl();
    await camera.init();
    expect(platform.opens, [true, false]);
    expect(camera.hasMicrophone, isFalse);
  });
}
