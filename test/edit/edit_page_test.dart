import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/edit/reorder_strip.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';
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

  testWidgets("the plus shows under the max and calls back", (tester) async {
    var adds = 0;
    await pumpPicker(
      tester,
      EditPage(items: [a, b], onAdd: () => adds++),
      settings: const PickerSettings(maxSelection: 3, filters: true),
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(adds, 1);
  });

  testWidgets("one item with room shows the plus", (tester) async {
    await pumpPicker(
      tester,
      EditPage(items: [a], onAdd: () {}),
      settings: settings,
    );
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets("one item at a max of 1 has no strip", (tester) async {
    await pumpPicker(
      tester,
      EditPage(items: [a], onAdd: () {}),
      settings: const PickerSettings(filters: true),
    );
    expect(find.byType(ReorderStrip), findsNothing);
  });

  testWidgets("no plus at the max", (tester) async {
    await pumpPicker(
      tester,
      EditPage(items: [a, b], onAdd: () {}),
      settings: const PickerSettings(maxSelection: 2, filters: true),
    );
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets("no plus with no add", (tester) async {
    await pumpPicker(tester, EditPage(items: [a, b]), settings: settings);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets("initial is shown first and a reorder is reported", (tester) async {
    List<MediaItem>? order;
    await pumpPicker(
      tester,
      EditPage(items: [a, b, v], initial: b, onReorder: (items) => order = items),
      settings: settings,
    );
    expect(tester.widget<PreviewImage>(find.byType(PreviewImage)).item, b);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey("a"))));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(order, [b, v, a]);
  });

  testWidgets("done shows progress over the whole screen and freezes the page while saving", (tester) async {
    final fakes = Fakes()..image.gate = Completer<void>();
    final filters = filtersOf([a]);
    await pumpPicker(
      tester,
      EditPage(items: [a], filterIndexes: filters),
      settings: settings,
      fakes: fakes,
    );
    await tester.tap(find.text("Warm"));
    await tester.pump();
    await tester.tap(find.text("Done"));
    await tester.pump();
    expect(find.text("Processing"), findsOneWidget);
    final barrier = find.ancestor(of: find.text("Processing"), matching: find.byType(ColoredBox)).last;
    expect(tester.getSize(barrier), const Size(400, 800));

    await tester.tap(find.text("Cool"), warnIfMissed: false);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(EditPage), findsOneWidget);
    expect(filters["a"]!.value, 1);

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

  testWidgets("esc goes back and enter is done", (tester) async {
    var backs = 0;
    final fakes = Fakes();
    await pumpPicker(
      tester,
      EditPage(items: [a], filterIndexes: filtersOf([a]), onBack: () => backs++),
      settings: settings,
      fakes: fakes,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(backs, 1);
    await tester.tap(find.text("Warm"));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(fakes.image.calls, hasLength(1));
  });

  testWidgets("tab reaches a filter and enter picks it instead of done", (tester) async {
    final fakes = Fakes();
    final filters = filtersOf([a]);
    await pumpPicker(
      tester,
      EditPage(items: [a], filterIndexes: filters),
      settings: settings,
      fakes: fakes,
    );
    final warm = find.ancestor(of: find.text("Warm"), matching: find.byType(FocusableActionDetector));
    for (var i = 0; i < 30; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused?.findAncestorWidgetOfExactType<FocusableActionDetector>() == tester.widget(warm)) break;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(filters[a.id]!.value, 1);
    expect(fakes.image.calls, isEmpty);
  });

  testWidgets("a mouse over a filter shows the click cursor", (tester) async {
    await pumpPicker(
      tester,
      EditPage(items: [a], filterIndexes: filtersOf([a])),
      settings: settings,
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.text("Warm")));
    await tester.pump();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);
    await gesture.removePointer();
  });

  testWidgets("on desktop a plain drag reorders", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      EditPage(items: [a, b], filterIndexes: filtersOf([a, b])),
      settings: settings,
      onResult: (r) => result = r,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey("a"))),
      kind: PointerDeviceKind.mouse,
    );
    // the first move only gets past the drag slop
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect((result! as List<PickedItem>).map((e) => e.file.path), ["/fake/b", "/fake/a"]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
