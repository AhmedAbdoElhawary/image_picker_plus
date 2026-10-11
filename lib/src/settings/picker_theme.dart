import 'package:flutter/widgets.dart';

/// the picker's colors, dark by default.
class PickerTheme {
  /// behind every page.
  final Color background;

  /// buttons, menus and empty cells.
  final Color surface;

  /// text and icons.
  final Color onSurface;

  /// less important text and icons.
  final Color onSurfaceMuted;

  /// selection, done and the focus ring.
  final Color accent;

  /// text and icons on [accent].
  final Color onAccent;

  /// behind the preview image.
  final Color scrim;

  /// behind the edit card on wide windows.
  final Color barrier;

  /// the capture button while a video records.
  final Color recording;

  /// [barrier] and [recording] have defaults.
  const PickerTheme({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.accent,
    required this.onAccent,
    required this.scrim,
    this.barrier = const Color(0x99000000),
    this.recording = const Color(0xFFFF3B30),
  });

  /// the shipped light colors.
  factory PickerTheme.light() => const PickerTheme(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F2F5),
    onSurface: Color(0xFF111114),
    onSurfaceMuted: Color(0xFF6E6E78),
    accent: Color(0xFF3B6EF5),
    onAccent: Color(0xFFFFFFFF),
    scrim: Color(0xFFFFFFFF),
  );

  /// the shipped dark colors.
  factory PickerTheme.dark() => const PickerTheme(
    background: Color(0xFF0E0E10),
    surface: Color(0xFF1C1C20),
    onSurface: Color(0xFFF4F4F6),
    onSurfaceMuted: Color(0xFF9A9AA4),
    accent: Color(0xFF5B8BFF),
    onAccent: Color(0xFFFFFFFF),
    scrim: Color(0xFF000000),
  );

  /// [custom], or the shipped one for [brightness].
  static PickerTheme resolve(PickerTheme? custom, Brightness brightness) {
    if (custom != null) return custom;
    return brightness == Brightness.dark ? PickerTheme.dark() : PickerTheme.light();
  }
}
