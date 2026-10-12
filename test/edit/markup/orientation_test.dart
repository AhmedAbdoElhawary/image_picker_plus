import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/orientation.dart';

void main() {
  const red = Color(0xFFFF0000);
  const text = TextMark(text: "Hi", color: red, center: Offset(0.2, 0.1), size: 0.1, angle: 0.3);
  const stroke = StrokeMark(points: [Offset(0.2, 0.1), Offset(0.9, 0.4)], color: red, width: 0.02);

  void expectOffset(Offset actual, Offset expected) {
    expect(actual.dx, closeTo(expected.dx, 1e-9));
    expect(actual.dy, closeTo(expected.dy, 1e-9));
  }

  test("a turn moves a text with the image, turns it and keeps its size on screen", () {
    final turned = rotateItem(text, 2) as TextMark;
    expectOffset(turned.center, const Offset(0.1, 0.8));
    expect(turned.angle, closeTo(0.3 - pi / 2, 1e-9));
    // a 2:1 image turned is 1:2, so the same text is twice the part of the new width
    expect(turned.size, closeTo(0.2, 1e-9));
  });

  test("a turn moves every point of a stroke and keeps its width on screen", () {
    final turned = rotateItem(stroke, 0.5) as StrokeMark;
    expectOffset(turned.points.first, const Offset(0.1, 0.8));
    expectOffset(turned.points.last, const Offset(0.4, 0.1));
    expect(turned.width, closeTo(0.01, 1e-9));
  });

  test("four turns of a square image are back at the start", () {
    MarkupItem item = text;
    for (var i = 0; i < 4; i++) {
      item = rotateItem(item, 1);
    }
    final back = item as TextMark;
    expectOffset(back.center, text.center);
    expect(back.angle, closeTo(text.angle - 2 * pi, 1e-9));
  });

  test("a flip moves a text without mirroring it, and mirrors a stroke", () {
    final flipped = flipItem(text) as TextMark;
    expectOffset(flipped.center, const Offset(0.8, 0.1));
    expect(flipped.angle, -0.3);
    expect((flipped.text, flipped.size), (text.text, text.size));
    final line = flipItem(stroke) as StrokeMark;
    expectOffset(line.points.first, const Offset(0.8, 0.1));
    expectOffset((flipItem(flipItem(stroke)) as StrokeMark).points.last, stroke.points.last);
  });
}
