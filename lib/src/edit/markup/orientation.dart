import 'dart:math';
import 'dart:ui';

import 'package:image_picker_plus/src/edit/markup/markup_item.dart';

/// [item] after a quarter turn counter clockwise of the image under it, [aspectBefore] is its
/// width / height before the turn. sizes are parts of the width, and the width changes.
MarkupItem rotateItem(MarkupItem item, double aspectBefore) {
  Offset turn(Offset point) => Offset(point.dy, 1 - point.dx);
  return switch (item) {
    TextMark() => item.copyWith(
      center: turn(item.center),
      size: item.size * aspectBefore,
      angle: item.angle - pi / 2,
    ),
    StrokeMark() => StrokeMark(
      points: [for (final point in item.points) turn(point)],
      color: item.color,
      width: item.width * aspectBefore,
    ),
  };
}

/// [item] after the image under it is mirrored left to right. a text moves, its letters don't mirror.
MarkupItem flipItem(MarkupItem item) => switch (item) {
  TextMark() => item.copyWith(center: Offset(1 - item.center.dx, item.center.dy), angle: -item.angle),
  StrokeMark() => StrokeMark(
    points: [for (final point in item.points) Offset(1 - point.dx, point.dy)],
    color: item.color,
    width: item.width,
  ),
};
