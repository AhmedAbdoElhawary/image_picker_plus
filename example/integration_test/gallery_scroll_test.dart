import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/gallery/gallery_cell.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:integration_test/integration_test.dart';

/// needs a device with photos and the gallery access already given.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("gallery opens fast and scrolls smooth", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => ImagePickerPlus.pick(
                context,
                settings: const PickerSettings(maxSelection: 10),
              ),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    final watch = Stopwatch()..start();
    await tester.tap(find.text("open"));
    while (!_thumbnailShown(tester) &&
        watch.elapsed < const Duration(seconds: 10)) {
      await tester.pump(const Duration(milliseconds: 5));
    }
    final firstThumbnail = watch.elapsedMilliseconds;
    await tester.pump(const Duration(seconds: 2));
    // after the first page, so the scroll is the only change
    final rssBefore = ProcessInfo.currentRss;

    final grid = find.byType(GridView);
    await binding.traceAction(() async {
      for (var i = 0; i < 40; i++) {
        await tester.fling(grid, const Offset(0, -900), 5000);
        await tester.pump(const Duration(milliseconds: 600));
      }
      for (var i = 0; i < 40; i++) {
        await tester.fling(grid, const Offset(0, 900), 5000);
        await tester.pump(const Duration(milliseconds: 600));
      }
    }, reportKey: "scroll_timeline");
    await tester.pump(const Duration(seconds: 2));
    final rssAfter = ProcessInfo.currentRss;

    binding.reportData = {
      ...?binding.reportData,
      "first_thumbnail_ms": firstThumbnail,
      "rss_before_mb": rssBefore ~/ (1024 * 1024),
      "rss_after_mb": rssAfter ~/ (1024 * 1024),
    };
  });
}

bool _thumbnailShown(WidgetTester tester) {
  final images = find.descendant(
    of: find.byType(GalleryCell),
    matching: find.byType(RawImage),
  );
  return images.evaluate().any(
    (element) => (element.widget as RawImage).image != null,
  );
}
