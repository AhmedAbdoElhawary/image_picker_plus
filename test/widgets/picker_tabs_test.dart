import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/camera_page.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';
import 'package:image_picker_plus/src/widgets/picker_tabs.dart';

import '../fakes/pump_picker.dart';

void main() {
  test("tabs from the settings", () {
    expect(PickerTabs.of(const PickerSettings(source: PickerSource.both, mediaType: MediaType.all)), [
      PickerTab.gallery,
      PickerTab.photo,
      PickerTab.video,
    ]);
    expect(PickerTabs.of(const PickerSettings(source: PickerSource.camera)), [PickerTab.photo]);
    expect(PickerTabs.of(const PickerSettings(source: PickerSource.camera, mediaType: MediaType.video)), [
      PickerTab.video,
    ]);
    expect(PickerTabs.of(const PickerSettings()), [PickerTab.gallery]);
  });

  testWidgets("both and all shows gallery, photo and video", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(source: PickerSource.both, mediaType: MediaType.all),
    );
    expect(find.byType(PickerTabs), findsOneWidget);
    expect(find.text("Gallery"), findsOneWidget);
    expect(find.text("Photo"), findsOneWidget);
    expect(find.text("Video"), findsOneWidget);
  });

  testWidgets("camera with image shows only the photo page and no tabs", (tester) async {
    await pumpPicker(tester, const PickerHome(), settings: const PickerSettings(source: PickerSource.camera));
    expect(find.byType(PickerTabs), findsNothing);
    expect(find.byType(CameraPage), findsOneWidget);
  });

  testWidgets("gallery shows no tab bar", (tester) async {
    await pumpPicker(tester, const PickerHome());
    expect(find.byType(PickerTabs), findsNothing);
    expect(find.byType(GalleryPage), findsOneWidget);
  });

  testWidgets("leaving the camera releases it and the gallery keeps its selection", (tester) async {
    final fakes = Fakes();
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: fakes,
      settings: const PickerSettings(source: PickerSource.both, maxSelection: 3),
    );
    await tester.tap(find.text("Select"));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey("3")));
    await tester.pump();
    await tester.tap(find.text("Photo"));
    await tester.pumpAndSettle();
    expect(fakes.camera.initCalls, 1);
    await tester.tap(find.text("Gallery"));
    await tester.pumpAndSettle();
    expect(fakes.camera.disposeCalls, 1);
    expect(find.text("2"), findsOneWidget);
  });
}
