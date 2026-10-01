import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';

void main() {
  test("custom theme wins", () {
    final custom = PickerTheme.dark();
    expect(PickerTheme.resolve(custom, Brightness.light), same(custom));
  });

  test("follows brightness without a custom theme", () {
    expect(PickerTheme.resolve(null, Brightness.dark).background, PickerTheme.dark().background);
    expect(PickerTheme.resolve(null, Brightness.light).background, PickerTheme.light().background);
  });
}
