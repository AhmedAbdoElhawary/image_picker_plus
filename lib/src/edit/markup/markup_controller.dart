import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';

/// what was added on one image, in draw order, with undo and redo over every change.
class MarkupController extends ValueNotifier<List<MarkupItem>> {
  static const int maxHistory = 100;

  final List<List<MarkupItem>> _undo = [];
  final List<List<MarkupItem>> _redo = [];
  final ValueNotifier<bool> canUndo = ValueNotifier(false);
  final ValueNotifier<bool> canRedo = ValueNotifier(false);

  MarkupController([super.value = const []]);

  void add(MarkupItem item) => _commit([...value, item]);

  void replace(MarkupItem old, MarkupItem next) {
    final index = value.indexOf(old);
    if (index < 0) return;
    _commit([...value]..[index] = next);
  }

  void remove(MarkupItem item) => _commit([...value]..remove(item));

  /// removes whole strokes the eraser [path] touches, never texts or stickers.
  /// [width] is a part of the image width like the stroke widths, [aspect] is the image width / height.
  void erase(List<Offset> path, double width, {double aspect = 1}) {
    // each point of one against each segment of the other, so a fast swipe with few points still hits
    bool near(List<Offset> points, List<Offset> line, double reach) {
      for (final point in points) {
        for (var i = 0; i < line.length; i++) {
          if (_distance(point, line[i], line[min(i + 1, line.length - 1)], aspect) <= reach) return true;
        }
      }
      return false;
    }

    bool touches(StrokeMark stroke) {
      final reach = (width + stroke.width) / 2;
      return near(path, stroke.points, reach) || near(stroke.points, path, reach);
    }

    _commit([
      for (final item in value)
        if (item is! StrokeMark || !touches(item)) item,
    ]);
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(value);
    value = _undo.removeLast();
    _sync();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(value);
    value = _redo.removeLast();
    _sync();
  }

  void _commit(List<MarkupItem> next) {
    if (listEquals(next, value)) return;
    _undo.add(value);
    if (_undo.length > maxHistory) _undo.removeAt(0);
    _redo.clear();
    value = next;
    _sync();
  }

  void _sync() {
    canUndo.value = _undo.isNotEmpty;
    canRedo.value = _redo.isNotEmpty;
  }

  /// from [point] to the segment [a] [b], measured in parts of the image width.
  static double _distance(Offset point, Offset a, Offset b, double aspect) {
    // y is a part of the height, so it's scaled to the width before measuring
    Offset scaled(Offset o) => Offset(o.dx, o.dy / aspect);
    final p = scaled(point);
    final start = scaled(a);
    final segment = scaled(b) - start;
    final length = segment.distanceSquared;
    if (length == 0) return (p - start).distance;
    final t = (((p - start).dx * segment.dx + (p - start).dy * segment.dy) / length).clamp(0.0, 1.0);
    return (p - (start + segment * t)).distance;
  }

  @override
  void dispose() {
    canUndo.dispose();
    canRedo.dispose();
    super.dispose();
  }
}
