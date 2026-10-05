import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item_view.dart';
import 'package:image_picker_plus/src/edit/markup/markup_view.dart';
import 'package:image_picker_plus/src/edit/markup/sticker_sheet.dart';
import 'package:image_picker_plus/src/edit/markup/text_editor.dart';
import 'package:image_picker_plus/src/settings/markup_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../../fakes/fake_gallery_service.dart';
import '../../fakes/pump_picker.dart';

void main() {
  final a = fakeItem("a");

  Future<MarkupController> open(
    WidgetTester tester, {
    MarkupOptions markup = const MarkupOptions(text: true, drawing: true),
    List<MarkupItem> items = const [],
    TextDirection direction = TextDirection.ltr,
  }) async {
    final controller = MarkupController(items);
    addTearDown(controller.dispose);
    await pumpPicker(
      tester,
      EditPage(items: [a], markups: {"a": controller}),
      settings: PickerSettings(cropRatios: const [], markup: markup),
      direction: direction,
    );
    return controller;
  }

  Finder canvas() => find.byType(MarkupView);

  group("text", () {
    testWidgets("the text tool opens the editor, done adds a centred text in the first color", (
      tester,
    ) async {
      final markup = await open(tester);
      await tester.tap(find.byTooltip("Text"));
      await tester.pumpAndSettle();
      expect(find.byType(TextEditor), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).autofocus, isTrue);
      await tester.enterText(find.byType(TextField), "Hi");
      await tester.tap(find.descendant(of: find.byType(TextEditor), matching: find.text("Done")));
      await tester.pumpAndSettle();
      final text = markup.value.single as TextMark;
      expect(
        (text.text, text.color, text.center),
        ("Hi", MarkupOptions.defaultColors.first, const Offset(0.5, 0.5)),
      );
    });

    testWidgets("a tap reopens it, emptying it removes it", (tester) async {
      const hi = TextMark(text: "Hi", color: Color(0xFFE53935), center: Offset(0.5, 0.5), size: 0.2);
      final markup = await open(tester, items: [hi]);
      await tester.tap(find.byTooltip("Text"));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(TextEditor), matching: find.text("Done")));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MarkupItemView));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, "Hi");
      await tester.enterText(find.byType(TextField), "  ");
      await tester.tap(find.descendant(of: find.byType(TextEditor), matching: find.text("Done")));
      await tester.pumpAndSettle();
      expect(markup.value, isEmpty);
    });

    testWidgets("a drag moves it as one undo step, the delete area only shows while dragging", (
      tester,
    ) async {
      const hi = TextMark(text: "Hi", color: Color(0xFFE53935), center: Offset(0.5, 0.5), size: 0.2);
      final markup = await open(tester, items: [hi]);
      await tester.tap(find.byTooltip("Draw"));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip("Text"));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(TextEditor), matching: find.text("Done")));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteArea), findsNothing);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(MarkupItemView)));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, -10));
        await tester.pump();
      }
      expect(find.byType(DeleteArea), findsOneWidget);
      await gesture.up();
      await tester.pump();
      final moved = markup.value.single as TextMark;
      expect(moved.center.dy, lessThan(0.5));
      markup.undo();
      expect(markup.value.single, hi);
    });

    testWidgets("dropping on the delete area removes it", (tester) async {
      const hi = TextMark(text: "Hi", color: Color(0xFFE53935), center: Offset(0.5, 0.3), size: 0.2);
      final markup = await open(tester, items: [hi]);
      await tester.tap(find.byTooltip("Text"));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(TextEditor), matching: find.text("Done")));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.byType(MarkupItemView)));
      for (var i = 0; i < 3; i++) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump();
      }
      await gesture.moveTo(tester.getCenter(find.byType(DeleteArea)));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(markup.value, isEmpty);
    });

    testWidgets("fonts show only when given, right to left texts keep their direction", (tester) async {
      final markup = await open(
        tester,
        markup: const MarkupOptions(text: true, fonts: ["Lobster"]),
        direction: TextDirection.rtl,
      );
      await tester.tap(find.byTooltip("Text"));
      await tester.pumpAndSettle();
      expect(find.text("Aa"), findsNWidgets(2));
      await tester.tap(find.text("Aa").last);
      await tester.enterText(find.byType(TextField), "مرحبا");
      await tester.tap(find.descendant(of: find.byType(TextEditor), matching: find.text("Done")));
      await tester.pumpAndSettle();
      final text = markup.value.single as TextMark;
      expect((text.font, text.direction), ("Lobster", TextDirection.rtl));
    });

    testWidgets("no fonts, no font control", (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip("Text"));
      await tester.pumpAndSettle();
      expect(find.text("Aa"), findsNothing);
    });

    testWidgets("size stays grabbable and under three image widths", (tester) async {
      const size = Size(300, 300);
      const tiny = TextMark(text: "x", color: Color(0xFF000000), center: Offset.zero, size: 0.0001);
      final clamped = MarkupItemView.clamp(tiny, size) as TextMark;
      expect(clamped.size * size.width * 1.2, closeTo(24, 0.01));
      const huge = StickerMark(index: 0, center: Offset.zero, width: 99);
      expect((MarkupItemView.clamp(huge, size) as StickerMark).width, 3);
    });
  });

  group("draw", () {
    Future<MarkupController> drawing(WidgetTester tester) async {
      final markup = await open(tester);
      await tester.tap(find.byTooltip("Draw"));
      await tester.pumpAndSettle();
      return markup;
    }

    testWidgets("a drag adds one stroke on lift, tiny moves are dropped", (tester) async {
      final markup = await drawing(tester);
      final start = tester.getCenter(canvas());
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0.3, 0));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(30, 10));
      expect(markup.value, isEmpty);
      await gesture.up();
      await tester.pump();
      final stroke = markup.value.single as StrokeMark;
      expect(stroke.points, hasLength(3));
      expect(stroke.color, MarkupOptions.defaultColors.first);
      expect(stroke.width, 0.012);
    });

    testWidgets("a second finger drops the stroke", (tester) async {
      final markup = await drawing(tester);
      final start = tester.getCenter(canvas());
      final one = await tester.startGesture(start);
      await one.moveBy(const Offset(20, 0));
      final two = await tester.startGesture(start + const Offset(0, 40));
      await one.up();
      await two.up();
      await tester.pump();
      expect(markup.value, isEmpty);
    });

    testWidgets("mouse and stylus draw too", (tester) async {
      final markup = await drawing(tester);
      for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.stylus]) {
        final gesture = await tester.startGesture(tester.getCenter(canvas()), kind: kind);
        await gesture.moveBy(const Offset(20, 20));
        await gesture.up();
        await tester.pump();
      }
      expect(markup.value, hasLength(2));
    });

    testWidgets("the eraser takes a stroke and leaves the text, ctrl z brings it back", (tester) async {
      final markup = await drawing(tester);
      final center = tester.getCenter(canvas());
      final gesture = await tester.startGesture(center - const Offset(40, 0));
      await gesture.moveBy(const Offset(80, 0));
      await gesture.up();
      await tester.pump();
      markup.add(const TextMark(text: "t", color: Color(0xFF000000), center: Offset(0.1, 0.1), size: 0.1));
      await tester.tap(find.byTooltip("Eraser"));
      await tester.pump();
      // a finger crosses in many small moves
      final erase = await tester.startGesture(center - const Offset(0, 10));
      for (var i = 0; i < 10; i++) {
        await erase.moveBy(const Offset(0, 2));
      }
      await erase.up();
      await tester.pump();
      expect(markup.value.single, isA<TextMark>());
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(markup.value, hasLength(2));
    });

    testWidgets("three sizes", (tester) async {
      final markup = await drawing(tester);
      await tester.tap(find.bySemanticsLabel("Size").last);
      await tester.pump();
      final gesture = await tester.startGesture(tester.getCenter(canvas()));
      await gesture.moveBy(const Offset(20, 0));
      await gesture.up();
      await tester.pump();
      expect((markup.value.single as StrokeMark).width, 0.024);
    });
  });

  group("stickers", () {
    final stickers = [MemoryImage(tinyPng), MemoryImage(tinyPng)];

    testWidgets("the button shows only with stickers", (tester) async {
      await open(tester);
      expect(find.byTooltip("Stickers"), findsNothing);
    });

    testWidgets("a tap in the sheet adds it in the middle, it moves like a text", (tester) async {
      final markup = await open(tester, markup: MarkupOptions(stickers: stickers));
      await tester.tap(find.byTooltip("Stickers"));
      await tester.pumpAndSettle();
      final tiles = find.descendant(of: find.byType(StickerSheet), matching: find.byType(InkWell));
      expect(tiles, findsNWidgets(2));
      await tester.tap(tiles.last);
      await tester.pumpAndSettle();
      final sticker = markup.value.single as StickerMark;
      expect((sticker.index, sticker.center, sticker.width), (1, const Offset(0.5, 0.5), 0.3));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(MarkupItemView)));
      for (var i = 0; i < 3; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();
      expect((markup.value.single as StickerMark).center.dx, greaterThan(0.5));
    });
  });

  testWidgets("esc leaves the mode, then the page", (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip("Draw"));
    await tester.pumpAndSettle();
    expect(find.byType(MarkupView), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MarkupView), findsNothing);
    expect(find.byType(EditPage), findsOneWidget);
  });
}
