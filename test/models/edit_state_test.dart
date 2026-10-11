import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

void main() {
  EditState roundTrip(EditState state) =>
      EditState.fromMap((jsonDecode(jsonEncode(state.toMap())) as Map).cast<String, Object?>());

  test("crop, ratio and filter survive a json round trip", () {
    const state = EditState(cropRect: Rect.fromLTWH(0.1, 0, 0.8, 1), ratio: CropRatio.square, filterIndex: 3);
    expect(roundTrip(state), state);
  });

  test("original ratio is written as a word, no crop writes no ratio", () {
    expect(const EditState(ratio: CropRatio.original).toMap()["ratio"], "original");
    expect(roundTrip(const EditState(ratio: CropRatio.original)).ratio, CropRatio.original);
    expect(const EditState().toMap().containsKey("ratio"), isFalse);
  });

  test("an empty or broken map gives the defaults", () {
    expect(EditState.fromMap(const {}), const EditState());
    expect(
      EditState.fromMap(const {
        "crop": [1, 2],
        "ratio": [0, 1],
        "filter": -2,
        "later": true,
      }),
      const EditState(),
    );
  });

  test("a turn, a flip or a slider is an edit", () {
    expect(const EditState(turns: 1).edited, isTrue);
    expect(const EditState(flipped: true).edited, isTrue);
    expect(const EditState(adjustments: Adjustments(contrast: 0.3)).edited, isTrue);
    expect(const EditState(turns: 0, adjustments: Adjustments.neutral).edited, isFalse);
  });

  test("turns, flip and sliders round trip, and are only written when set", () {
    const state = EditState(
      turns: 3,
      flipped: true,
      adjustments: Adjustments(brightness: -0.5, warmth: 0.25),
    );
    expect(roundTrip(state), state);
    final plain = const EditState().toMap();
    expect(
      [plain.containsKey("turns"), plain.containsKey("flip"), plain.containsKey("adjust")],
      [false, false, false],
    );
  });

  test("a map from before them, or a broken one, loads them as defaults", () {
    final older = EditState.fromMap(const {
      "crop": [0, 0, 1, 1],
      "filter": 2,
    });
    expect((older.turns, older.flipped, older.adjustments), (0, false, Adjustments.neutral));
    final broken = EditState.fromMap(const {
      "turns": "x",
      "flip": "yes",
      "adjust": [1],
    });
    expect((broken.turns, broken.flipped, broken.adjustments), (0, false, Adjustments.neutral));
    expect(EditState.fromMap(const {"turns": 5}).turns, 1);
    expect(
      EditState.fromMap(const {
        "adjust": [3, 0, 0, 0],
      }).adjustments.brightness,
      1,
    );
  });
}
