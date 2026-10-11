import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/camera_tools.dart';
import 'package:image_picker_plus/src/camera/capture_button.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/camera_options.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';

import '../fakes/fake_camera_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  const camera = PickerSettings(source: PickerSource.camera);

  testWidgets("no camera shows the message with close", (tester) async {
    Object? result = "open";
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: camera,
      fakes: Fakes(camera: FakeCameraService(failure: CameraFailure.noCamera)),
      onResult: (r) => result = r,
    );
    expect(find.text("There is no camera"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets("denied shows open settings", (tester) async {
    final fakes = Fakes(camera: FakeCameraService(failure: CameraFailure.denied));
    await pumpPicker(tester, const PickerHome(), settings: camera, fakes: fakes);
    expect(find.text("Allow camera access to continue"), findsOneWidget);
    await tester.tap(find.text("Open settings"));
    expect(fakes.gallery.openSettingsCalls, 1);
  });

  testWidgets("a photo with editing off pops the item", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(source: PickerSource.camera, cropRatios: []),
      onResult: (r) => result = r,
    );
    expect(find.byKey(const Key("fake-preview")), findsOneWidget);
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect((result! as List<PickedItem>).single.file.path, "/fake/photo.jpg");
  });

  testWidgets("a photo with filters on opens the edit page", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(source: PickerSource.camera, filters: PickerFilter.all),
    );
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(find.byType(EditPage), findsOneWidget);
  });

  testWidgets("a photo with crop opens the edit page with the ratio button", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(
        source: PickerSource.camera,
        cropRatios: [CropRatio.square, CropRatio.portrait],
      ),
    );
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(find.byType(CropView), findsOneWidget);
    await tester.tap(find.text("1:1"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("4:5"));
    await tester.pumpAndSettle();
    expect(tester.widget<CropView>(find.byType(CropView)).controller.ratio, CropRatio.portrait);
  });

  testWidgets("a tap on the preview focuses there and shows the ring for a moment", (tester) async {
    final fakes = Fakes();
    await pumpPicker(tester, const PickerHome(), settings: camera, fakes: fakes);
    final preview = find.byKey(const Key("fake-preview"));
    final box = tester.getRect(preview);
    await tester.tapAt(box.topLeft + Offset(box.width / 4, box.height / 2));
    await tester.pump();
    expect(fakes.camera.lastFocus!.dx, closeTo(0.25, 0.01));
    expect(fakes.camera.lastFocus!.dy, closeTo(0.5, 0.01));
    final ring = find.byWidgetPredicate((widget) => widget is TweenAnimationBuilder<double>);
    expect(ring, findsOneWidget);
    await tester.pumpAndSettle();
    expect(ring, findsNothing);
  });

  testWidgets("the plus on a photo keeps it, and the next photo goes after it", (tester) async {
    final fakes = Fakes();
    Object? result;
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: fakes,
      settings: const PickerSettings(source: PickerSource.camera, maxSelection: 3, filters: PickerFilter.all),
      onResult: (r) => result = r,
    );
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Warm"));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(EditPage), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    fakes.camera.photoPath = "/fake/photo2.jpg";
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(tester.widget<EditPage>(find.byType(EditPage)).initial?.id, "/fake/photo2.jpg");

    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    final items = result! as List<PickedItem>;
    expect(items.map((e) => e.file.path), ["/fake/photo.jpg.edited.jpg", "/fake/photo2.jpg"]);
  });

  testWidgets("video records and stops, with the microphone note when denied", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(source: PickerSource.camera, mediaType: MediaType.video),
      fakes: Fakes(camera: FakeCameraService(mic: false, cameras: 1, flash: false)),
      onResult: (r) => result = r,
    );
    expect(find.text("Allow microphone access to record sound"), findsOneWidget);
    expect(find.byIcon(Icons.cameraswitch_rounded), findsNothing);
    expect(find.byIcon(Icons.flash_off_rounded), findsNothing);
    await tester.tap(find.byType(CaptureButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text("0:02"), findsOneWidget);
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect((result! as List<PickedItem>).single.type, MediaType.video);
  });

  group("extras", () {
    Future<Fakes> openCamera(
      WidgetTester tester, {
      CameraOptions options = const CameraOptions(),
      Fakes? fakes,
    }) async {
      final used = fakes ?? Fakes();
      await pumpPicker(
        tester,
        const PickerHome(),
        settings: PickerSettings(source: PickerSource.camera, cropRatios: const [], camera: options),
        fakes: used,
      );
      return used;
    }

    Finder preview() => find.byKey(const Key("fake-preview"));

    testWidgets("zoom buttons from the range, a tap zooms", (tester) async {
      final fakes = await openCamera(tester);
      expect(find.text("1x"), findsOneWidget);
      expect(find.text("2x"), findsOneWidget);
      expect(find.text("8x"), findsOneWidget);
      expect(find.bySemanticsLabel("Zoom 2x"), findsOneWidget);
      await tester.tap(find.text("2x"));
      await tester.pump();
      expect(fakes.camera.zoomCalls, [2]);
    });

    testWidgets("a pinch zooms and a tap still focuses", (tester) async {
      final fakes = await openCamera(tester);
      final center = tester.getCenter(preview());
      final one = await tester.startGesture(center - const Offset(20, 0));
      final two = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();
      await one.moveBy(const Offset(-40, 0));
      await two.moveBy(const Offset(40, 0));
      await tester.pump();
      await one.up();
      await two.up();
      await tester.pump();
      expect(fakes.camera.zoomCalls, isNotEmpty);
      expect(fakes.camera.zoomCalls.last, greaterThan(1));
      await tester.tapAt(center);
      await tester.pump();
      expect(fakes.camera.lastFocus, isNotNull);
    });

    testWidgets("no zoom row when turned off or the camera can't zoom", (tester) async {
      await openCamera(tester, options: const CameraOptions(zoomButtons: false));
      expect(find.text("1x"), findsNothing);
    });

    testWidgets("no zoom row for a fixed camera", (tester) async {
      await openCamera(tester, fakes: Fakes(camera: FakeCameraService()..maxZoom = 1));
      expect(find.text("1x"), findsNothing);
    });

    testWidgets("timer counts down then takes the photo, a second tap cancels", (tester) async {
      Object? result;
      await pumpPicker(
        tester,
        const PickerHome(),
        settings: const PickerSettings(source: PickerSource.camera, cropRatios: []),
        onResult: (r) => result = r,
      );
      Finder timerValue(String value) =>
          find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.value == value);
      expect(timerValue("Timer off"), findsOneWidget);
      await tester.tap(find.byTooltip("Timer"));
      await tester.pump();
      expect(timerValue("Timer 3 seconds"), findsOneWidget);
      await tester.tap(find.byType(CaptureButton));
      await tester.pump();
      expect(find.descendant(of: find.byType(Countdown), matching: find.text("3")), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byType(CaptureButton));
      await tester.pump(const Duration(seconds: 5));
      expect(result, isNull);

      await tester.tap(find.byType(CaptureButton));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect((result! as List<PickedItem>).single.file.path, "/fake/photo.jpg");
    });

    testWidgets("on video the timer starts the recording, and stopping never waits", (tester) async {
      final fakes = Fakes();
      await pumpPicker(
        tester,
        const PickerHome(),
        settings: const PickerSettings(source: PickerSource.camera, mediaType: MediaType.video),
        fakes: fakes,
      );
      await tester.tap(find.byTooltip("Timer"));
      await tester.pump();
      await tester.tap(find.byType(CaptureButton));
      await tester.pump();
      expect(fakes.camera.recording, isFalse);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(fakes.camera.recording, isTrue);
      await tester.tap(find.byType(CaptureButton));
      await tester.pump();
      expect(fakes.camera.recording, isFalse);
    });

    testWidgets("reduced motion shows the countdown with no animation", (tester) async {
      await openCamera(tester);
      await tester.tap(find.byTooltip("Timer"));
      await tester.pump();
      await tester.tap(find.byType(CaptureButton));
      await tester.pump();
      final switcher = find.descendant(of: find.byType(Countdown), matching: find.byType(AnimatedSwitcher));
      expect(tester.widget<AnimatedSwitcher>(switcher).duration, Duration.zero);
      expect(find.descendant(of: find.byType(Countdown), matching: find.text("3")), findsOneWidget);
      await tester.tap(find.byType(CaptureButton));
      await tester.pump();
    });

    testWidgets("no timer or grid buttons when turned off", (tester) async {
      await openCamera(tester, options: const CameraOptions(timer: false, grid: false));
      expect(find.byTooltip("Timer"), findsNothing);
      expect(find.byTooltip("Grid"), findsNothing);
    });

    testWidgets("the grid button toggles the grid, sized like the preview", (tester) async {
      await openCamera(tester);
      expect(find.byType(GridLines), findsNothing);
      await tester.tap(find.byTooltip("Grid"));
      await tester.pump();
      expect(find.byType(GridLines), findsOneWidget);
      expect(tester.getSize(find.byType(GridLines)), tester.getSize(preview()));
      await tester.tap(find.byTooltip("Grid"));
      await tester.pump();
      expect(find.byType(GridLines), findsNothing);
    });

    testWidgets("gridOn starts with it, also with no button", (tester) async {
      await openCamera(tester, options: const CameraOptions(grid: false, gridOn: true));
      expect(find.byType(GridLines), findsOneWidget);
      expect(find.byTooltip("Grid"), findsNothing);
    });

    testWidgets("the overlay gets the preview size and doesn't block focus or zoom", (tester) async {
      Size? size;
      final fakes = await openCamera(
        tester,
        options: CameraOptions(
          gridOn: true,
          overlay: (context, previewSize) {
            size = previewSize;
            return const ColoredBox(key: Key("card"), color: Color(0x33000000));
          },
        ),
      );
      expect(size, tester.getSize(preview()));
      expect(find.byKey(const Key("card")), findsOneWidget);
      expect(find.byType(GridLines), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.byKey(const Key("card"))));
      await tester.pump();
      expect(fakes.camera.lastFocus, isNotNull);
      await tester.tap(find.byIcon(Icons.flip_camera_android_rounded));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("card")), findsOneWidget);
    });
  });
}
