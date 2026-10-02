import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/pump_picker.dart';

void main() {
  testWidgets("rtl puts the close icon on the right and mirrors the badges", (tester) async {
    await pumpPicker(
      tester,
      const GalleryPage(),
      direction: TextDirection.rtl,
      settings: const PickerSettings(maxSelection: 3),
    );
    final close = tester.getCenter(find.byIcon(Icons.close_rounded));
    expect(close.dx, greaterThan(200));
    final cell = tester.getRect(find.byKey(const ValueKey("0")));
    final badge = tester.getCenter(find.descendant(of: find.byKey(const ValueKey("0")), matching: find.text("1")));
    expect(badge.dx, lessThan(cell.center.dx));
  });

  testWidgets("ltr keeps the close icon on the left", (tester) async {
    await pumpPicker(tester, const GalleryPage());
    expect(tester.getCenter(find.byIcon(Icons.close_rounded)).dx, lessThan(200));
  });

  testWidgets("reduced motion: changes settle in one frame", (tester) async {
    await pumpPicker(tester, const GalleryPage(), settings: const PickerSettings(maxSelection: 3));
    await tester.tap(find.byKey(const ValueKey("4")));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets("normal motion animates the selection", (tester) async {
    await pumpPicker(
      tester,
      const GalleryPage(),
      settings: const PickerSettings(maxSelection: 3),
      disableAnimations: false,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey("4")));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
  });
}
