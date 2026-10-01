import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/capture_controller.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<CaptureController> start(FakeCameraService camera) async {
    final controller = CaptureController(create: () => camera);
    await controller.init();
    return controller;
  }

  test("no camera and denied states", () async {
    expect((await start(FakeCameraService(failure: CameraFailure.noCamera))).state.value, CaptureState.noCamera);
    expect((await start(FakeCameraService(failure: CameraFailure.denied))).state.value, CaptureState.denied);
  });

  test("switch and flash follow the device", () async {
    final one = await start(FakeCameraService(cameras: 1, flash: false));
    expect(one.cameraCount.value, 1);
    expect(one.hasFlash.value, isFalse);
    await one.switchCamera();
    await one.toggleFlash();
    expect(one.flash.value, isFalse);

    final camera = FakeCameraService();
    final two = await start(camera);
    await two.switchCamera();
    expect(camera.switchCalls, 1);
    await two.toggleFlash();
    expect(camera.lastFlash, isTrue);
  });

  test("photo returns an item", () async {
    final controller = await start(FakeCameraService());
    final item = await controller.takePhoto();
    expect(item!.type, MediaType.image);
  });

  test("video start then stop returns a video item", () async {
    final controller = await start(FakeCameraService());
    expect(await controller.toggleRecording(), isNull);
    expect(controller.state.value, CaptureState.recording);
    final item = await controller.toggleRecording();
    expect(item!.type, MediaType.video);
    expect(controller.state.value, CaptureState.ready);
  });

  test("no microphone shows it and photo still works", () async {
    final controller = await start(FakeCameraService(mic: false));
    expect(controller.microphone.value, isFalse);
    expect(controller.state.value, CaptureState.ready);
    expect(await controller.takePhoto(), isNotNull);
  });

  test("a double tap takes one photo", () async {
    final controller = await start(FakeCameraService());
    final results = await Future.wait([controller.takePhoto(), controller.takePhoto()]);
    expect(results.whereType<Object>().length, 1);
  });

  test("pause releases the camera and resume opens it again", () async {
    final cameras = <FakeCameraService>[];
    final controller = CaptureController(create: () => FakeCameraService()..let(cameras.add));
    await controller.init();
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(cameras.first.disposeCalls, 1);
    expect(controller.service, isNull);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(cameras.length, 2);
    expect(controller.state.value, CaptureState.ready);
    controller.dispose();
    expect(cameras.last.disposeCalls, 1);
  });
}

extension<T> on T {
  T let(void Function(T value) action) {
    action(this);
    return this;
  }
}
