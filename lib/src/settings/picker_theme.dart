import 'package:flutter/widgets.dart';

class PickerTheme {
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color accent;
  final Color onAccent;
  final Color scrim;

  const PickerTheme({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.accent,
    required this.onAccent,
    required this.scrim,
  });

  factory PickerTheme.light() => const PickerTheme(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F2F5),
    onSurface: Color(0xFF111114),
    onSurfaceMuted: Color(0xFF6E6E78),
    accent: Color(0xFF3B6EF5),
    onAccent: Color(0xFFFFFFFF),
    scrim: Color(0x99000000),
  );

  factory PickerTheme.dark() => const PickerTheme(
    background: Color(0xFF0E0E10),
    surface: Color(0xFF1C1C20),
    onSurface: Color(0xFFF4F4F6),
    onSurfaceMuted: Color(0xFF9A9AA4),
    accent: Color(0xFF5B8BFF),
    onAccent: Color(0xFFFFFFFF),
    scrim: Color(0xB3000000),
  );

  static PickerTheme resolve(PickerTheme? custom, Brightness brightness) {
    if (custom != null) return custom;
    return brightness == Brightness.dark ? PickerTheme.dark() : PickerTheme.light();
  }
}
