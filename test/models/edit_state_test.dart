import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
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
}
