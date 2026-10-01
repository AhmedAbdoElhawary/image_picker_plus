import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';

void main() {
  test("maxReachedFor puts the number in", () {
    expect(const PickerTexts().maxReachedFor(5), "You can select up to 5 items");
    expect(const PickerTexts(maxReached: "max {max}").maxReachedFor(2), "max 2");
  });

  test("one name per filter", () {
    expect(const PickerTexts().filterNames.length, filters.length);
    for (final matrix in filters) {
      expect(matrix.length, 20);
    }
  });
}
