import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum MarkupTool { text, draw, emoji }

enum TextBackground { none, solid, clear }

/// positions are normalized 0..1 of the whole image as shown, sizes are parts of its width,
/// so markup stays on the same part of the photo at any crop and resolution.
sealed class MarkupItem {
  const MarkupItem();

  Map<String, Object?> toMap();

  /// null for a kind this version doesn't know, it's dropped.
  static MarkupItem? fromMap(Map<String, Object?> map) {
    try {
      return switch (map["k"]) {
        "text" => TextMark(
          text: map["text"]! as String,
          color: Color((map["color"]! as num).toInt()),
          background: TextBackground.values.byName(map["bg"] as String? ?? "none"),
          font: map["font"] as String?,
          direction: map["rtl"] == true ? TextDirection.rtl : TextDirection.ltr,
          center: _offset(map),
          size: (map["size"]! as num).toDouble(),
          angle: (map["angle"] as num? ?? 0).toDouble(),
        ),
        "stroke" => StrokeMark(
          points: [for (final pair in _pairs(map["points"]! as List)) Offset(pair.$1, pair.$2)],
          color: Color((map["color"]! as num).toInt()),
          width: (map["width"]! as num).toDouble(),
        ),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  static Offset _offset(Map<String, Object?> map) =>
      Offset((map["x"]! as num).toDouble(), (map["y"]! as num).toDouble());

  static Iterable<(double, double)> _pairs(List<Object?> flat) sync* {
    for (var i = 0; i + 1 < flat.length; i += 2) {
      yield ((flat[i]! as num).toDouble(), (flat[i + 1]! as num).toDouble());
    }
  }
}

class TextMark extends MarkupItem {
  final String text;
  final Color color;
  final TextBackground background;

  /// null is the app's font.
  final String? font;
  final TextDirection direction;
  final Offset center;

  /// font size as a part of the image width.
  final double size;

  /// radians.
  final double angle;

  const TextMark({
    required this.text,
    required this.color,
    required this.center,
    required this.size,
    this.background = TextBackground.none,
    this.font,
    this.direction = TextDirection.ltr,
    this.angle = 0,
  });

  TextMark copyWith({
    String? text,
    Color? color,
    TextBackground? background,
    String? Function()? font,
    Offset? center,
    double? size,
    double? angle,
  }) => TextMark(
    text: text ?? this.text,
    color: color ?? this.color,
    background: background ?? this.background,
    font: font == null ? this.font : font(),
    direction: direction,
    center: center ?? this.center,
    size: size ?? this.size,
    angle: angle ?? this.angle,
  );

  @override
  Map<String, Object?> toMap() => {
    "k": "text",
    "text": text,
    "color": color.toARGB32(),
    "bg": background.name,
    "font": font,
    "rtl": direction == TextDirection.rtl,
    "x": center.dx,
    "y": center.dy,
    "size": size,
    "angle": angle,
  };

  @override
  bool operator ==(Object other) =>
      other is TextMark &&
      other.text == text &&
      other.color == color &&
      other.background == background &&
      other.font == font &&
      other.direction == direction &&
      other.center == center &&
      other.size == size &&
      other.angle == angle;

  @override
  int get hashCode => Object.hash(text, color, background, font, direction, center, size, angle);
}

class StrokeMark extends MarkupItem {
  final List<Offset> points;
  final Color color;

  /// a part of the image width.
  final double width;

  const StrokeMark({required this.points, required this.color, required this.width});

  @override
  Map<String, Object?> toMap() => {
    "k": "stroke",
    "color": color.toARGB32(),
    "width": width,
    "points": [
      for (final point in points) ...[point.dx, point.dy],
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is StrokeMark && other.color == color && other.width == width && listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(color, width, Object.hashAll(points));
}
