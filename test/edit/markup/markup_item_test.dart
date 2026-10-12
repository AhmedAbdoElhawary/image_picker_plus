import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';

void main() {
  const text = TextMark(
    text: "Day 1 🏔️",
    color: Color(0xFFFFFFFF),
    background: TextBackground.solid,
    font: "Lobster",
    direction: TextDirection.rtl,
    center: Offset(0.5, 0.12),
    size: 0.08,
    angle: -0.1,
  );
  const stroke = StrokeMark(
    points: [Offset(0.21, 0.4), Offset(0.22, 0.41)],
    color: Color(0xFFE53935),
    width: 0.012,
  );

  MarkupItem? roundTrip(MarkupItem item) =>
      MarkupItem.fromMap((jsonDecode(jsonEncode(item.toMap())) as Map).cast<String, Object?>());

  test("equal by value", () {
    expect(text, text.copyWith());
    expect(
      stroke,
      const StrokeMark(
        points: [Offset(0.21, 0.4), Offset(0.22, 0.41)],
        color: Color(0xFFE53935),
        width: 0.012,
      ),
    );
    expect(text.copyWith(size: 0.3), isNot(text));
    expect(text.copyWith(font: () => null).font, isNull);
  });

  test("every kind survives a json round trip", () {
    expect(roundTrip(text), text);
    expect(roundTrip(stroke), stroke);
    expect(stroke.toMap()["points"], [0.21, 0.4, 0.22, 0.41]);
  });

  test("an unknown or broken item is dropped", () {
    expect(MarkupItem.fromMap(const {"k": "arrow"}), isNull);
    expect(MarkupItem.fromMap(const {"k": "text"}), isNull);
  });

  test("markup is part of the edit state map and makes it edited", () {
    const state = EditState(markup: [text, stroke]);
    expect(state.edited, isTrue);
    final back = EditState.fromMap((jsonDecode(jsonEncode(state.toMap())) as Map).cast<String, Object?>());
    expect(back, state);
    expect(const EditState().toMap().containsKey("markup"), isFalse);
    expect(
      EditState.fromMap(const {
        "markup": [
          {"k": "arrow"},
          {
            "k": "stroke",
            "points": [0, 0],
            "color": 0,
            "width": 0.1,
          },
        ],
      }).markup,
      [
        const StrokeMark(points: [Offset.zero], color: Color(0x00000000), width: 0.1),
      ],
    );
  });
}
