import 'package:image_picker_plus/src/settings/picker_texts.dart';

/// a look on the edit page's filter strip.
class PickerFilter {
  /// null for a shipped filter, its name then comes from [PickerTexts.filterNames].
  final String? name;

  /// 5x4 for `ColorFilter.matrix`, offsets are 0 to 255. the picker throws when it isn't 20 values.
  final List<double> matrix;

  /// [matrix] has to be 20 values.
  const PickerFilter({required this.name, required this.matrix});

  /// the 13 shipped looks. "Normal" isn't one, the strip always starts with it.
  static const List<PickerFilter> all = [
    PickerFilter(
      name: null,
      matrix: [
        1.2, 0, 0, 0, 0, //
        0, 1.0, 0, 0, 0, //
        0, 0, 0.8, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        0.9, 0, 0, 0, 0, //
        0, 1.0, 0, 0, 0, //
        0, 0, 1.2, 0, 10, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        0.9, 0.05, 0.15, 0, 0, //
        0.05, 0.9, 0.15, 0, 0, //
        0.15, 0.15, 0.8, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        1.2, -0.1, 0.2, 0, 0, //
        0.1, 1.1, 0.1, 0, 0, //
        0.1, 0.2, 1.1, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        1.5, 0.5, -0.3, 0, -40, //
        0.3, 1.3, 0.1, 0, -40, //
        0.2, 0.3, 1.2, 0, -40, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        0.85, 0.1, 0.1, 0, 15, //
        0.1, 0.85, 0.1, 0, 15, //
        0.1, 0.1, 0.85, 0, 15, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        0.393, 0.769, 0.189, 0, 0, //
        0.349, 0.686, 0.168, 0, 0, //
        0.272, 0.534, 0.131, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        1.2, 0.1, -0.1, 0, 0, //
        -0.1, 1, 0.1, 0, 0, //
        -0.1, 0, 1.2, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        1, 0, 0, 0, 40, //
        0, 1, 0, 0, 40, //
        0, 0, 1, 0, 40, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        1.5, 0, 0, 0, -64, //
        0, 1.5, 0, 0, -64, //
        0, 0, 1.5, 0, -64, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        0.9, 0.1, 0.1, 0, 25, //
        0.1, 0.9, 0.1, 0, 25, //
        0.1, 0.1, 0.9, 0, 25, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        0.3, 0.59, 0.11, 0, 0, //
        0.3, 0.59, 0.11, 0, 0, //
        0.3, 0.59, 0.11, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    ),
    PickerFilter(
      name: null,
      matrix: [
        0.45, 0.88, 0.17, 0, -50, //
        0.45, 0.88, 0.17, 0, -50, //
        0.45, 0.88, 0.17, 0, -50, //
        0, 0, 0, 1, 0, //
      ],
    ),
  ];

  /// no change, what "Normal" applies.
  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// [name], or the shipped name from [texts].
  String nameIn(PickerTexts texts) {
    if (name case final name?) return name;
    final index = all.indexOf(this) + 1;
    return index > 0 && index < texts.filterNames.length ? texts.filterNames[index] : "";
  }
}

/// the matrix of strip [index] in [filters], 0 is Normal and so is an index past the end.
/// [strength] 0 is no filter and 1 the full one.
List<double> filterMatrix(List<PickerFilter> filters, int index, {double strength = 1}) {
  final matrix = index > 0 && index <= filters.length ? filters[index - 1].matrix : PickerFilter.identity;
  if (strength == 1) return matrix;
  const identity = PickerFilter.identity;
  return [for (var i = 0; i < 20; i++) identity[i] + (matrix[i] - identity[i]) * strength];
}
