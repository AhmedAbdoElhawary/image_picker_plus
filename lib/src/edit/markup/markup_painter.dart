import 'package:flutter/rendering.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';

/// the one place markup is drawn, for the preview and the saved file, so they match.
/// [size] is the whole image, before the crop.
class MarkupPainter extends CustomPainter {
  final List<MarkupItem> items;

  /// the stroke being drawn, kept apart so only it repaints while drawing.
  final StrokeMark? active;

  const MarkupPainter({required this.items, this.active});

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      paintItem(canvas, size, item);
    }
    final active = this.active;
    if (active != null) paintItem(canvas, size, active);
  }

  static void paintItem(Canvas canvas, Size size, MarkupItem item) {
    switch (item) {
      case StrokeMark():
        _stroke(canvas, size, item);
      case TextMark():
        final painter = _text(item, size);
        final box = _textBox(painter, item, size);
        _turned(canvas, size, item.center, item.angle, () {
          if (item.background != TextBackground.none) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Offset(-box.width / 2, -box.height / 2) & box,
                Radius.circular(box.height / 4),
              ),
              Paint()..color = backgroundOf(item),
            );
          }
          painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
        });
        painter.dispose();
    }
  }

  /// the box an item takes before it's turned, in the pixels of [size].
  static Size measure(MarkupItem item, Size size) {
    switch (item) {
      case TextMark():
        final painter = _text(item, size);
        final box = _textBox(painter, item, size);
        painter.dispose();
        return box;
      case StrokeMark():
        return Size.zero;
    }
  }

  static TextPainter _text(TextMark item, Size size) => TextPainter(
    text: TextSpan(
      text: item.text,
      style: TextStyle(
        color: item.color,
        fontSize: item.size * size.width,
        fontFamily: item.font,
        height: 1.2,
      ),
    ),
    textDirection: item.direction,
    textAlign: TextAlign.center,
  )..layout();

  static Size _textBox(TextPainter painter, TextMark item, Size size) {
    final padding = item.size * size.width * 0.25;
    return Size(painter.width + padding * 2, painter.height + padding * 2);
  }

  /// the text's own color at the opposite lightness, so it always reads.
  static Color backgroundOf(TextMark item) {
    if (item.background == TextBackground.none) return item.color.withValues(alpha: 0);
    final light = item.color.computeLuminance() > 0.5;
    return HSLColor.fromColor(item.color)
        .withLightness(light ? 0.08 : 0.95)
        .toColor()
        .withValues(alpha: item.background == TextBackground.solid ? 1 : 0.5);
  }

  static void _turned(Canvas canvas, Size size, Offset center, double angle, VoidCallback draw) {
    canvas
      ..save()
      ..translate(center.dx * size.width, center.dy * size.height)
      ..rotate(angle);
    draw();
    canvas.restore();
  }

  static void _stroke(Canvas canvas, Size size, StrokeMark stroke) {
    final points = [for (final point in stroke.points) Offset(point.dx * size.width, point.dy * size.height)];
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width * size.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      return;
    }
    // curves through the midpoints, straight segments look jagged on a slow drag
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset.lerp(points[i], points[i + 1], 0.5)!;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MarkupPainter oldDelegate) =>
      !identical(oldDelegate.items, items) || oldDelegate.active != active;
}
