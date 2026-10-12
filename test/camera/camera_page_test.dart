import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/camera_controls.dart';
import 'package:image_picker_plus/src/camera/camera_page.dart';
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

  testWidgets("landscape puts grid, flash, shutter, switch and timer in one column beside the preview", (
    tester,
  ) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(source: PickerSource.both),
      size: const Size(740, 360),
    );
    await tester.tap(find.text("Photo"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final column = [
      GridButton,
      FlashButton,
      CaptureButton,
      SwitchCameraButton,
      TimerButton,
    ].map((type) => tester.getCenter(find.byType(type))).toList();
    for (var i = 1; i < column.length; i++) {
      expect(column[i].dx, closeTo(column[0].dx, 1));
      expect(column[i].dy, greaterThan(column[i - 1].dy));
    }
    expect(column[0].dx, greaterThan(tester.getCenter(find.byKey(const Key("fake-preview"))).dx));
  });

  testWidgets("a short phone on its side fits the column while recording", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(source: PickerSource.camera, mediaType: MediaType.video),
      size: const Size(740, 360),
      textScale: 1.5,
    );
    await tester.tap(find.byType(CaptureButton));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  // the camera sits on one half of an open foldable, so the image has that half's shape
  for (final (name, fold, tall) in [
    ("a fold across shows the image tall", const Rect.fromLTRB(420, 0, 420, 700), true),
    ("a fold along shows the image wide", const Rect.fromLTRB(0, 350, 840, 350), false),
  ]) {
    testWidgets(name, (tester) async {
      await pumpPicker(
        tester,
        const PickerHome(),
        settings: camera,
        size: const Size(840, 700),
        displayFeatures: [
          DisplayFeature(bounds: fold, type: DisplayFeatureType.fold, state: DisplayFeatureState.postureFlat),
        ],
      );
      final size = tester.getSize(find.byKey(const Key("fake-preview")));
      expect(size.height > size.width, tall);
    });
  }

  testWidgets("a wide screen covers the space and cuts the photo to what was seen", (tester) async {
    final fakes = Fakes();
    Object? result;
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: fakes,
      settings: const PickerSettings(source: PickerSource.camera, cropRatios: []),
      size: const Size(800, 400),
      onResult: (r) => result = r,
    );
    final preview = tester.getSize(find.byKey(const Key("fake-preview")));
    expect(preview.width, greaterThanOrEqualTo(800));
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    final cut = fakes.image.calls.single.$2.cropRect;
    // the 3:4 photo is cut to the wide space, its full width and a middle band of its height
    expect((cut.left, cut.width), (0, 1));
    expect(cut.height, lessThan(0.5));
    expect(cut.center.dy, closeTo(0.5, 0.001));
    expect((result! as List<PickedItem>).single.file.path, "/fake/photo.jpg.edited.jpg");
  });

  testWidgets("a phone held up fits the preview and keeps the whole photo", (tester) async {
    final fakes = Fakes();
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: fakes,
      settings: const PickerSettings(source: PickerSource.camera, cropRatios: []),
    );
    expect(tester.getSize(find.byKey(const Key("fake-preview"))).width, lessThanOrEqualTo(400));
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(fakes.image.calls, isEmpty);
  });

  testWidgets("a plugin error shows try again, which opens the camera", (tester) async {
    final fakes = Fakes(camera: FakeCameraService()..error = StateError("plugin"));
    await pumpPicker(tester, const PickerHome(), settings: camera, fakes: fakes);
    expect(find.text("Something went wrong"), findsOneWidget);
    fakes.camera.error = null;
    await tester.tap(find.text("Try again"));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("fake-preview")), findsOneWidget);
  });

  testWidgets("a failed photo shows a message and the camera stays", (tester) async {
    final fakes = Fakes(camera: FakeCameraService()..photoError = StateError("plugin"));
    await pumpPicker(tester, const PickerHome(), settings: camera, fakes: fakes);
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(find.text("Something went wrong"), findsOneWidget);
    expect(find.byKey(const Key("fake-preview")), findsOneWidget);
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

  testWidgets("the camera is let go under the edit page and opens again on back", (tester) async {
    final fakes = Fakes();
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: fakes,
      settings: const PickerSettings(source: PickerSource.camera, filters: PickerFilter.all),
    );
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(find.byType(CameraPage, skipOffstage: false), findsNothing);
    expect(fakes.camera.disposeCalls, 1);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(CameraPage), findsOneWidget);
    expect(fakes.camera.initCalls, 2);
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
