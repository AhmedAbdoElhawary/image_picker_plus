import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';

void main() {
  const red = Color(0xFFFF0000);
  StrokeMark line(double y) => StrokeMark(points: [Offset(0.1, y), Offset(0.9, y)], color: red, width: 0.01);
  const text = TextMark(text: "Hi", color: red, center: Offset(0.5, 0.5), size: 0.1);

  test("add, undo, redo", () {
    final controller = MarkupController();
    controller.add(line(0.1));
    controller.add(line(0.2));
    expect(controller.value, [line(0.1), line(0.2)]);
    controller.undo();
    expect(controller.value, [line(0.1)]);
    expect((controller.canUndo.value, controller.canRedo.value), (true, true));
    controller.redo();
    expect(controller.value, [line(0.1), line(0.2)]);
    expect(controller.canRedo.value, isFalse);
  });

  test("a new change clears redo, undo with nothing does nothing", () {
    final controller = MarkupController();
    controller.undo();
    expect(controller.value, isEmpty);
    controller.add(line(0.1));
    controller.undo();
    controller.add(line(0.3));
    controller.redo();
    expect(controller.value, [line(0.3)]);
  });

  test("history keeps the last 100 steps", () {
    final controller = MarkupController();
    for (var i = 0; i < 101; i++) {
      controller.add(line(i / 200));
    }
    for (var i = 0; i < 150; i++) {
      controller.undo();
    }
    expect(controller.value, hasLength(1));
  });

  test("a move is one undo step, no change is none", () {
    final controller = MarkupController()..add(text);
    final moved = text.copyWith(center: const Offset(0.2, 0.2));
    controller.replace(text, moved);
    controller.replace(moved, moved);
    expect(controller.value, [moved]);
    controller.undo();
    expect(controller.value, [text]);
  });

  test("remove", () {
    final controller = MarkupController()..add(text);
    controller.remove(text);
    expect(controller.value, isEmpty);
  });

  test("the eraser takes the strokes it touches and leaves the rest", () {
    final controller = MarkupController()
      ..add(line(0.2))
      ..add(line(0.6))
      ..add(text.copyWith(center: const Offset(0.5, 0.2)));
    controller.erase(const [Offset(0.5, 0.21)], 0.02);
    expect(controller.value, [line(0.6), text.copyWith(center: const Offset(0.5, 0.2))]);
    controller.erase(const [Offset(0.5, 0.9)], 0.02);
    expect(controller.value, hasLength(2));
  });

  test("transform maps the items and every undo and redo step, with no step of its own", () {
    final controller = MarkupController()
      ..add(text)
      ..add(line(0.2))
      ..undo();
    controller.transform((item) => item is TextMark ? item.copyWith(size: 0.2) : item);
    expect((controller.value.single as TextMark).size, 0.2);
    controller.redo();
    expect((controller.value.first as TextMark).size, 0.2);
    controller.undo();
    controller.undo();
    expect(controller.value, isEmpty);
    expect(controller.canUndo.value, isFalse);
  });
}
