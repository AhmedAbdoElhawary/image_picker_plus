import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/gallery/gallery_cell.dart';
import 'package:image_picker_plus/src/gallery/gallery_grid.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';

import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';

import '../fakes/pump_picker.dart';

void main() {
  int columns(WidgetTester tester) {
    final grid = tester.widget<GridView>(find.byType(GridView));
    return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount;
  }

  bool beside(WidgetTester tester) =>
      tester.getTopLeft(find.byType(GalleryGrid)).dx > tester.getTopLeft(find.byType(MediaPreview)).dx;

  testWidgets("phone: preview above with 4 columns", (tester) async {
    await pumpPicker(tester, const PickerHome(), size: const Size(400, 800));
    expect(columns(tester), 4);
    expect(beside(tester), isFalse);
    // the grid runs under the preview, its first row starts below it
    expect(
      tester.getTopLeft(find.byType(GalleryCell).first).dy,
      greaterThan(tester.getBottomLeft(find.byType(MediaPreview)).dy),
    );
  });

  testWidgets("columns and cell shape from the settings", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      size: const Size(1300, 900),
      settings: const PickerSettings(gridColumns: 2, gridCellAspectRatio: 0.5),
    );
    expect(columns(tester), 2);
    final size = tester.getSize(find.byType(GalleryCell).first);
    expect(size.height, closeTo(size.width * 2, 0.5));
  });

  testWidgets("landscape tablet: preview beside with 6 columns", (tester) async {
    await pumpPicker(tester, const PickerHome(), size: const Size(1000, 700));
    expect(columns(tester), 6);
    expect(beside(tester), isTrue);
  });

  testWidgets("big screen: preview beside with 8 columns", (tester) async {
    await pumpPicker(tester, const PickerHome(), size: const Size(1300, 900));
    expect(columns(tester), 8);
    expect(beside(tester), isTrue);
  });

  testWidgets("no overflow with large text", (tester) async {
    await pumpPicker(tester, const PickerHome(), size: const Size(360, 640), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets("no overflow on a short landscape phone", (tester) async {
    await pumpPicker(tester, const PickerHome(), size: const Size(640, 360), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });
}
