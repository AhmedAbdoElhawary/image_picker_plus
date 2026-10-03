import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/capture_button.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';

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
      settings: const PickerSettings(source: PickerSource.camera, filters: true),
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
      settings: const PickerSettings(source: PickerSource.camera, maxSelection: 3, filters: true),
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
}
