import 'package:flutter/painting.dart';

class MarkupOptions {
  /// add, edit, move and delete text, and emojis from their own button.
  final bool text;

  /// freehand pen with undo, redo and an eraser.
  final bool drawing;

  /// font families the app registers, the user can switch a text between the app's font and these.
  /// empty shows no font control.
  final List<String> fonts;

  /// for text and the pen, at least one.
  final List<Color> colors;

  const MarkupOptions({
    this.text = false,
    this.drawing = false,
    this.fonts = const [],
    this.colors = defaultColors,
  });

  /// what people draw with, not the picker's theme, so it doesn't follow light and dark.
  static const List<Color> defaultColors = [
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  bool get enabled => text || drawing;
}
