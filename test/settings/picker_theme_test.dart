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

  test("barrier has a default, so custom themes don't break", () {
    const theme = PickerTheme(
      background: Color(0xFF000001),
      surface: Color(0xFF000002),
      onSurface: Color(0xFF000003),
      onSurfaceMuted: Color(0xFF000004),
      accent: Color(0xFF000005),
      onAccent: Color(0xFF000006),
      scrim: Color(0xFF000007),
    );
    expect(theme.barrier, const Color(0x99000000));
  });
}
