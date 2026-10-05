import 'dart:async';

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
    expect(
      (await start(FakeCameraService(failure: CameraFailure.noCamera))).state.value,
      CaptureState.noCamera,
    );
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
  group("zoom", () {
    test("the range comes from the camera and starts at 1", () async {
      final camera = FakeCameraService()..minZoom = 0.6;
      final controller = await start(camera);
      expect((controller.minZoom.value, controller.maxZoom.value, controller.zoom.value), (0.6, 8.0, 1.0));
    });

    test("a level past the range is clamped", () async {
      final camera = FakeCameraService();
      final controller = await start(camera);
      await controller.setZoom(20);
      expect(controller.zoom.value, 8);
      expect(camera.zoomCalls, [8]);
    });

    test("switching camera resets the zoom and reads the range again", () async {
      final camera = FakeCameraService();
      final controller = await start(camera);
      await controller.setZoom(3);
      camera.maxZoom = 4;
      await controller.switchCamera();
      expect((controller.zoom.value, controller.maxZoom.value), (1.0, 4.0));
    });

    test("only one call at a time goes to the camera, then the latest", () async {
      final camera = FakeCameraService()..zoomGate = Completer();
      final controller = await start(camera);
      final first = controller.setZoom(2);
      await controller.setZoom(3);
      await controller.setZoom(4);
      await controller.setZoom(5);
      expect(controller.zoom.value, 5);
      expect(camera.zoomCalls, [2]);
      camera.zoomGate!.complete();
      await first;
      expect(camera.zoomCalls, [2, 5]);
    });
  });

  group("timer", () {
    test("cycles 3, 10, off", () async {
      final controller = await start(FakeCameraService());
      final seen = <int>[];
      for (var i = 0; i < 3; i++) {
        controller.cycleTimer();
        seen.add(controller.timer.value);
      }
      expect(seen, [3, 10, 0]);
    });

    testWidgets("counts down then runs once", (tester) async {
      final controller = await start(FakeCameraService());
      controller.cycleTimer();
      var ends = 0;
      controller.startCountdown(() => ends++);
      final seen = <int?>[controller.countdown.value];
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
        seen.add(controller.countdown.value);
      }
      expect(seen, [3, 2, 1, null]);
      expect(ends, 1);
      controller.dispose();
    });

    testWidgets("a cancel, a camera switch or a pause stops it", (tester) async {
      final controller = await start(FakeCameraService());
      controller.cycleTimer();
      var ends = 0;
      for (final stop in <Future<void> Function()>[
        () async => controller.cancelCountdown(),
        controller.switchCamera,
        () async => controller.didChangeAppLifecycleState(AppLifecycleState.paused),
      ]) {
        controller.startCountdown(() => ends++);
        await tester.pump(const Duration(seconds: 1));
        await stop();
        expect(controller.countdown.value, isNull);
        await tester.pump(const Duration(seconds: 5));
      }
      expect(ends, 0);
      controller.dispose();
    });

    testWidgets("dispose stops it", (tester) async {
      final controller = await start(FakeCameraService());
      controller.cycleTimer();
      var ends = 0;
      controller.startCountdown(() => ends++);
      controller.dispose();
      await tester.pump(const Duration(seconds: 5));
      expect(ends, 0);
    });
  });
}

extension<T> on T {
  T let(void Function(T value) action) {
    action(this);
    return this;
  }
}
