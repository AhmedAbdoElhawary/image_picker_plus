import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  final a = fakeItem("a");
  final b = fakeItem("b");
  final v = fakeItem("v", type: MediaType.video);
  const settings = PickerSettings(maxSelection: 5, filters: true);

  // the gallery or camera owns these, the page only shares them
  Map<String, ValueNotifier<int>> filtersOf(List<MediaItem> items) => {
    for (final item in items)
      if (!item.isVideo) item.id: ValueNotifier(0),
  };

  testWidgets("the filter strip changes only the current image", (tester) async {
    final fakes = Fakes();
    Object? result;
    await pumpPicker(
      tester,
      EditPage(items: [a, b], filterIndexes: filtersOf([a, b])),
      fakes: fakes,
      settings: settings,
      onResult: (r) => result = r,
    );
    await tester.tap(find.text("Cool"));
    await tester.pump();
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    final items = result! as List<PickedItem>;
    expect(items.map((e) => e.edited), [true, false]);
    expect(fakes.image.calls.single.$2.filterIndex, 2);
  });

  testWidgets("a video shows the note and the filters are off", (tester) async {
    await pumpPicker(
      tester,
      EditPage(items: [v, a], filterIndexes: filtersOf([v, a])),
      settings: settings,
    );
    expect(find.text("Videos can only be reordered"), findsOneWidget);
    final ignore = tester.widget<IgnorePointer>(
      find.ancestor(of: find.byType(ListView).first, matching: find.byType(IgnorePointer)).first,
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets("dragging in the strip changes the result order", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      EditPage(items: [a, b, v], filterIndexes: filtersOf([a, b, v])),
      settings: settings,
      onResult: (r) => result = r,
    );
    final first = find.byKey(const ValueKey("a"));
    final gesture = await tester.startGesture(tester.getCenter(first));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect((result! as List<PickedItem>).map((e) => e.file.path), ["/fake/b", "/fake/v", "/fake/a"]);
  });

  testWidgets("done shows progress while saving", (tester) async {
    final fakes = Fakes()..image.gate = Completer<void>();
    await pumpPicker(
      tester,
      EditPage(items: [a], filterIndexes: filtersOf([a])),
      settings: settings,
      fakes: fakes,
    );
    await tester.tap(find.text("Warm"));
    await tester.pump();
    await tester.tap(find.text("Done"));
    await tester.pump();
    expect(find.text("Saving"), findsOneWidget);
    fakes.image.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(EditPage), findsNothing);
  });

  testWidgets("a failed save shows the message and stays", (tester) async {
    final fakes = Fakes()..image.fail = true;
    await pumpPicker(
      tester,
      EditPage(items: [a], filterIndexes: filtersOf([a])),
      settings: settings,
      fakes: fakes,
    );
    await tester.tap(find.text("Warm"));
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save the images, try again"), findsOneWidget);
    expect(find.byType(EditPage), findsOneWidget);
  });

  testWidgets("tap in the strip makes it current", (tester) async {
    await pumpPicker(
      tester,
      EditPage(items: [a, v], filterIndexes: filtersOf([a, v])),
      settings: settings,
    );
    expect(find.text("Videos can only be reordered"), findsNothing);
    await tester.tap(find.byKey(const ValueKey("v")));
    await tester.pumpAndSettle();
    expect(find.text("Videos can only be reordered"), findsOneWidget);
  });
}
