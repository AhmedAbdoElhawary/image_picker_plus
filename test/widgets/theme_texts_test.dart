import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/camera_page.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';

import '../fakes/fake_camera_service.dart';
import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  const custom = PickerTheme(
    background: Color(0xFF102030),
    surface: Color(0xFF203040),
    onSurface: Color(0xFFEEEEEE),
    onSurfaceMuted: Color(0xFFAAAAAA),
    accent: Color(0xFFFF8800),
    onAccent: Color(0xFF000000),
    scrim: Color(0x88000000),
  );
  const texts = PickerTexts(next: "Weiter", done: "Fertig", noCamera: "Keine Kamera");
  const settings = PickerSettings(theme: custom, texts: texts, filters: true);

  Color? background(WidgetTester tester) => tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor;

  testWidgets("custom theme and texts on the gallery", (tester) async {
    await pumpPicker(
      tester,
      const GalleryPage(),
      settings: const PickerSettings(theme: custom, texts: texts),
    );
    expect(find.text("Weiter"), findsOneWidget);
    expect(background(tester), custom.background);
  });

  testWidgets("custom texts on the camera message", (tester) async {
    await pumpPicker(
      tester,
      const CameraPage(video: false),
      settings: settings,
      fakes: Fakes(camera: FakeCameraService(failure: CameraFailure.noCamera)),
    );
    expect(find.text("Keine Kamera"), findsOneWidget);
  });

  testWidgets("custom theme and texts on the edit page", (tester) async {
    await pumpPicker(tester, EditPage(items: [fakeItem("a")]), settings: settings);
    expect(find.text("Fertig"), findsOneWidget);
    expect(background(tester), custom.background);
  });

  testWidgets("a dark app with no theme uses the dark one", (tester) async {
    await pumpPicker(tester, const GalleryPage(), brightness: Brightness.dark);
    expect(background(tester), PickerTheme.dark().background);
  });

  test("no hard coded colors outside the theme", () {
    final hits = <String>[];
    for (final file in Directory("lib/src").listSync(recursive: true).whereType<File>()) {
      if (file.path.endsWith("picker_theme.dart")) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'\bColors\.(?!transparent\b)|Color\(0x').hasMatch(lines[i])) {
          hits.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(hits, isEmpty);
  });
}
