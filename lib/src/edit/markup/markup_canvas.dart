import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/cropped_image.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/filtered_image.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item_view.dart';
import 'package:image_picker_plus/src/edit/markup/markup_layer.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';
import 'package:image_picker_plus/src/edit/markup/pen_controls.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';

/// the current image cropped like it'll be saved, with its markup to move or draw on.
class MarkupCanvas extends StatelessWidget {
  final EditController controller;
  final bool drawing;
  final ValueNotifier<(MarkupItem, MarkupItem)?> moving;
  final ValueNotifier<StrokeMark?> active;

  /// left out while it's open in the editor.
  final TextMark? editingFrom;

  /// the color and width a new stroke gets, read when it starts, so a change doesn't build the canvas again.
  final ValueListenable<StrokeMark> pen;
  final ValueListenable<bool> erasing;
  final ValueChanged<TextMark> onTapText;
  final void Function(MarkupItem mark, MarkupItem to, Offset pointer) onMove;
  final void Function(MarkupItem mark, MarkupItem to, Offset pointer) onEnd;

  const MarkupCanvas({
    required this.controller,
    required this.drawing,
    required this.moving,
    required this.active,
    required this.editingFrom,
    required this.pen,
    required this.erasing,
    required this.onTapText,
    required this.onMove,
    required this.onEnd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final item = controller.current.value;
    final markup = controller.markups[item.id]!;
    final orientation = controller.crops[item.id];
    final crop = orientation?.value ?? EditState.full;
    final imageAspect = orientation?.imageAspect ?? (item.height == 0 ? 1.0 : item.width / item.height);
    Widget canvas = AspectRatio(
      aspectRatio: imageAspect * crop.width / crop.height,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          CroppedImage(
            rect: crop,
            child: LayoutBuilder(
              builder: (context, whole) {
                final size = whole.biggest;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FilteredImage(
                      item: item,
                      filter: controller.filterIndexes[item.id],
                      strength: controller.filterStrengths[item.id],
                      adjustments: controller.adjustments[item.id],
                      crop: null,
                      orientation: orientation,
                      markup: null,
                    ),
                    MarkupLayer(controller: markup, moving: moving, hidden: editingFrom, active: active),
                    if (drawing)
                      _Pen(size: size, markup: markup, active: active, pen: pen, erasing: erasing)
                    else
                      ValueListenableBuilder<List<MarkupItem>>(
                        valueListenable: markup,
                        builder: (context, items, _) => Stack(
                          children: [
                            for (final mark in items)
                              if (mark is! StrokeMark && mark != editingFrom)
                                MarkupItemView(
                                  item: mark,
                                  size: size,
                                  onTap: mark is TextMark ? () => onTapText(mark) : null,
                                  onMove: (to, pointer) => onMove(mark, to, pointer),
                                  onEnd: (to, pointer) => onEnd(mark, to, pointer),
                                ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          // not clipped, a text dragged to the delete button stays seen past the image
          CroppedImage(
            rect: crop,
            clip: false,
            child: IgnorePointer(
              child: ValueListenableBuilder<(MarkupItem, MarkupItem)?>(
                valueListenable: moving,
                builder: (context, moving, _) => CustomPaint(
                  size: Size.infinite,
                  painter: MarkupPainter(items: [?moving?.$2]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    canvas = Hero(
      tag: markup,
      // both ways, the edit page's window would show the image past the crop
      flightShuttleBuilder: (_, _, _, _, _) => PickerScope.of(context).wrap(
        CroppedImage(
          rect: crop,
          child: FilteredImage(
            item: item,
            filter: controller.filterIndexes[item.id],
            strength: controller.filterStrengths[item.id],
            adjustments: controller.adjustments[item.id],
            crop: null,
            orientation: orientation,
            markup: markup,
          ),
        ),
      ),
      child: canvas,
    );
    // two fingers zoom while drawing, one finger draws
    if (drawing) canvas = InteractiveViewer(panEnabled: false, maxScale: 5, child: canvas);
    return Center(child: canvas);
  }
}

/// raw pointers, not in the gesture arena, so the viewer's pinch and the pen never fight.
class _Pen extends StatefulWidget {
  final Size size;
  final MarkupController markup;
  final ValueNotifier<StrokeMark?> active;
  final ValueListenable<StrokeMark> pen;
  final ValueListenable<bool> erasing;

  const _Pen({
    required this.size,
    required this.markup,
    required this.active,
    required this.pen,
    required this.erasing,
  });

  @override
  State<_Pen> createState() => _PenState();
}

class _PenState extends State<_Pen> {
  int _pointers = 0;

  Offset _normalized(Offset local) => Offset(local.dx / widget.size.width, local.dy / widget.size.height);

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final active = widget.active;
    final eraser = PickerScope.of(context).theme.onSurface.withValues(alpha: 0.4);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _pointers++;
        if (_pointers > 1) {
          // a second finger is a pinch, the stroke so far is dropped
          active.value = null;
          return;
        }
        final pen = widget.pen.value;
        final erasing = widget.erasing.value;
        active.value = StrokeMark(
          points: [_normalized(event.localPosition)],
          color: erasing ? eraser : pen.color,
          width: erasing ? PenControls.eraserWidth : pen.width,
        );
      },
      onPointerMove: (event) {
        final stroke = active.value;
        if (stroke == null || _pointers > 1) return;
        final point = _normalized(event.localPosition);
        final last = stroke.points.last;
        final moved = Offset((point.dx - last.dx) * size.width, (point.dy - last.dy) * size.height);
        if (moved.distance < 1) return;
        active.value = StrokeMark(
          points: [...stroke.points, point],
          color: stroke.color,
          width: stroke.width,
        );
      },
      onPointerUp: (_) {
        _pointers = max(0, _pointers - 1);
        final stroke = active.value;
        if (stroke == null) return;
        active.value = null;
        widget.erasing.value
            ? widget.markup.erase(stroke.points, stroke.width, aspect: size.width / size.height)
            : widget.markup.add(stroke);
      },
      onPointerCancel: (_) {
        _pointers = max(0, _pointers - 1);
        active.value = null;
      },
    );
  }
}
