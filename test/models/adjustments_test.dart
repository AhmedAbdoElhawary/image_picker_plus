import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';

void main() {
  /// [rgb] through a 5x4 [matrix], like ColorFilter.matrix with full alpha.
  List<double> apply(List<double> matrix, List<double> rgb) => [
    for (var row = 0; row < 3; row++)
      matrix[row * 5] * rgb[0] +
          matrix[row * 5 + 1] * rgb[1] +
          matrix[row * 5 + 2] * rgb[2] +
          matrix[row * 5 + 3] * 255 +
          matrix[row * 5 + 4],
  ];

  void expectRgb(List<double> actual, List<double> expected) {
    for (var i = 0; i < 3; i++) {
      expect(actual[i], closeTo(expected[i], 0.5));
    }
  }

  test("neutral changes nothing", () {
    expect(Adjustments.neutral.isNeutral, isTrue);
    expect(const Adjustments(warmth: 0.1).isNeutral, isFalse);
    expectRgb(apply(Adjustments.neutral.matrix, [10, 120, 250]), [10, 120, 250]);
    expect(composeMatrix(PickerFilter.all[3].matrix, Adjustments.neutral), PickerFilter.all[3].matrix);
  });

  test("each slider at its end", () {
    expectRgb(apply(const Adjustments(brightness: 1).matrix, [100, 100, 100]), [164, 164, 164]);
    expectRgb(apply(const Adjustments(contrast: -1).matrix, [10, 200, 90]), [128, 128, 128]);
    final grey = apply(const Adjustments(saturation: -1).matrix, [255, 0, 0]);
    expect((grey[0] - grey[1]).abs() + (grey[1] - grey[2]).abs(), lessThan(0.01));
    expectRgb(apply(const Adjustments(warmth: 1).matrix, [100, 100, 100]), [124, 100, 76]);
  });

  test("the filter goes first, the sliders on top", () {
    final sepia = PickerFilter.all[6].matrix;
    final composed = composeMatrix(sepia, const Adjustments(saturation: -1));
    final filtered = apply(sepia, [200, 40, 90]);
    final grey = apply(composed, [200, 40, 90]);
    final luma = 0.2126 * filtered[0] + 0.7152 * filtered[1] + 0.0722 * filtered[2];
    expectRgb(grey, [luma, luma, luma]);
  });

  test("copyWith and equality", () {
    const a = Adjustments(brightness: 0.2);
    expect(a.copyWith(contrast: 0.5), const Adjustments(brightness: 0.2, contrast: 0.5));
    expect(a.hashCode, const Adjustments(brightness: 0.2).hashCode);
  });
}
