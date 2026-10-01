import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/gallery/gallery_grid.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';

import '../fakes/pump_picker.dart';

void main() {
  int columns(WidgetTester tester) {
    final grid = tester.widget<GridView>(find.byType(GridView));
    return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount;
  }

  bool beside(WidgetTester tester) =>
      tester.getTopLeft(find.byType(GalleryGrid)).dx > tester.getTopLeft(find.byType(MediaPreview)).dx;

  testWidgets("phone: preview above with 4 columns", (tester) async {
    await pumpPicker(tester, const GalleryPage(), size: const Size(400, 800));
    expect(columns(tester), 4);
    expect(beside(tester), isFalse);
    expect(
      tester.getTopLeft(find.byType(GalleryGrid)).dy,
      greaterThan(tester.getTopLeft(find.byType(MediaPreview)).dy),
    );
  });

  testWidgets("landscape tablet: preview beside with 6 columns", (tester) async {
    await pumpPicker(tester, const GalleryPage(), size: const Size(1000, 700));
    expect(columns(tester), 6);
    expect(beside(tester), isTrue);
  });

  testWidgets("big screen: preview beside with 8 columns", (tester) async {
    await pumpPicker(tester, const GalleryPage(), size: const Size(1300, 900));
    expect(columns(tester), 8);
    expect(beside(tester), isTrue);
  });

  testWidgets("no overflow with large text", (tester) async {
    await pumpPicker(tester, const GalleryPage(), size: const Size(360, 640), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets("no overflow on a short landscape phone", (tester) async {
    await pumpPicker(tester, const GalleryPage(), size: const Size(640, 360), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });
}
