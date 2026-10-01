import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/camera_page.dart';
import 'package:image_picker_plus/src/camera/capture_button.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_camera_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  testWidgets("no camera shows the message with close", (tester) async {
    Object? result = "open";
    await pumpPicker(
      tester,
      const CameraPage(video: false),
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
    await pumpPicker(tester, const CameraPage(video: false), fakes: fakes);
    expect(find.text("Allow camera access to continue"), findsOneWidget);
    await tester.tap(find.text("Open settings"));
    expect(fakes.gallery.openSettingsCalls, 1);
  });

  testWidgets("a photo with editing off pops the item", (tester) async {
    Object? result;
    await pumpPicker(tester, const CameraPage(video: false), onResult: (r) => result = r);
    expect(find.byKey(const Key("fake-preview")), findsOneWidget);
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect((result! as List<PickedItem>).single.file.path, "/fake/photo.jpg");
  });

  testWidgets("a photo with filters on opens the edit page", (tester) async {
    await pumpPicker(tester, const CameraPage(video: false), settings: const PickerSettings(filters: true));
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(find.byType(EditPage), findsOneWidget);
  });

  testWidgets("a photo with crop opens the edit page with the ratio button", (tester) async {
    await pumpPicker(
      tester,
      const CameraPage(video: false),
      settings: const PickerSettings(cropRatios: [CropRatio.square, CropRatio.portrait]),
    );
    await tester.tap(find.byType(CaptureButton));
    await tester.pumpAndSettle();
    expect(find.byType(CropView), findsOneWidget);
    await tester.tap(find.text("1:1"));
    await tester.pump();
    expect(find.text("4:5"), findsOneWidget);
  });

  testWidgets("video records and stops, with the microphone note when denied", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      const CameraPage(video: true),
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
}
