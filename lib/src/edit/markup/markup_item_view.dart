import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/haptic_feedback.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';

/// a text or emoji the user can move, pinch, twist or tap. it's drawn by the layer under it, this only takes the touches.
class MarkupItemView extends StatefulWidget {
  final MarkupItem item;

  /// the whole image on screen, the item's numbers are parts of it.
  final Size size;

  /// where it is during a move, with the pointer on screen, null when the move ends.
  final void Function(MarkupItem item, Offset pointer) onMove;

  /// the move ended at [pointer] with the item at [item].
  final void Function(MarkupItem item, Offset pointer) onEnd;
  final VoidCallback? onTap;

  const MarkupItemView({
    required this.item,
    required this.size,
    required this.onMove,
    required this.onEnd,
    this.onTap,
    super.key,
  });

  /// small enough to still grab, big enough to stay on the photo.
  static MarkupItem clamp(MarkupItem item, Size size) => switch (item) {
    TextMark() => item.copyWith(size: item.size.clamp(_minSide / 1.2 / size.width, 1.0)),
    StrokeMark() => item,
  };

  static const double _minSide = 24;

  @override
  State<MarkupItemView> createState() => _MarkupItemViewState();
}

class _MarkupItemViewState extends State<MarkupItemView> {
  /// the item a finger is on, a second item can't be grabbed until it's let go.
  static _MarkupItemViewState? _holder;

  /// every finger on screen while this is held, in the order they went down.
  final Map<int, Offset> _pointers = {};
  MarkupItem? _start;
  MarkupItem? _now;
  (Offset, double, double) _from = (Offset.zero, 1, 0);
  Offset _down = Offset.zero;
  bool _pinched = false;

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  void _grab(PointerDownEvent event) {
    if (_holder != null) return;
    _holder = this;
    _down = event.position;
    _pinched = false;
    _start = _now = null;
    // a global route sees the second finger wherever it lands, not only on the item
    GestureBinding.instance.pointerRouter.addGlobalRoute(_route);
  }

  void _release() {
    if (_holder != this) return;
    _holder = null;
    _pointers.clear();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_route);
  }

  /// the middle of the first two fingers, how far apart they are and their angle.
  (Offset, double, double) _span() {
    final points = _pointers.values.take(2).toList();
    if (points.length < 2) return (points.first, 1, 0);
    final between = points[1] - points[0];
    return ((points[0] + points[1]) / 2, max(between.distance, 1), between.direction);
  }

  /// a finger went down or up, so the next move starts from where things are now.
  void _restart() {
    _start = _now ?? widget.item;
    if (_pointers.isNotEmpty) _from = _span();
  }

  void _route(PointerEvent event) {
    switch (event) {
      case PointerDownEvent():
        _pointers[event.pointer] = event.position;
        if (_pointers.length > 1) _pinched = true;
        _restart();
      case PointerMoveEvent() when _pointers.containsKey(event.pointer):
        _pointers[event.pointer] = event.position;
        final start = _start;
        if (start == null) return;
        if (_now == null && !_pinched && (event.position - _down).distance < kTouchSlop) return;
        final (focal, distance, angle) = _span();
        final (fromFocal, fromDistance, fromAngle) = _from;
        final now = _now = _moved(start, focal - fromFocal, distance / fromDistance, angle - fromAngle);
        widget.onMove(now, _pointers.values.first);
      case PointerUpEvent() || PointerCancelEvent() when _pointers.containsKey(event.pointer):
        final last = _pointers.remove(event.pointer)!;
        if (_pointers.isNotEmpty) return _restart();
        final now = _now;
        _release();
        if (now != null) {
          widget.onEnd(now, last);
        } else if (event is PointerUpEvent && !_pinched) {
          widget.onTap?.call();
        }
      default:
        break;
    }
  }

  MarkupItem _moved(MarkupItem start, Offset delta, double scale, double rotation) {
    final shift = Offset(delta.dx / widget.size.width, delta.dy / widget.size.height);
    final next = switch (start) {
      TextMark() => start.copyWith(
        center: start.center + shift,
        size: start.size * scale,
        angle: start.angle + rotation,
      ),
      StrokeMark() => start,
    };
    return MarkupItemView.clamp(next, widget.size);
  }

  void _signal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final turn = HardwareKeyboard.instance.isShiftPressed;
    final next = turn
        ? _moved(widget.item, Offset.zero, 1, event.scrollDelta.dy / 200)
        : _moved(widget.item, Offset.zero, exp(-event.scrollDelta.dy / 200), 0);
    widget.onEnd(next, event.position);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final (center, angle) = switch (item) {
      TextMark() => (item.center, item.angle),
      StrokeMark() => (Offset.zero, 0.0),
    };
    final box = MarkupPainter.measure(item, widget.size);
    final width = max(box.width, PickerLayout.minTouch);
    final height = max(box.height, PickerLayout.minTouch);
    return Positioned(
      left: center.dx * widget.size.width - width / 2,
      top: center.dy * widget.size.height - height / 2,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: angle,
        // raw pointers, the second finger is often outside the item so a gesture detector never sees it
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _grab,
          onPointerSignal: (event) => GestureBinding.instance.pointerSignalResolver.register(event, _signal),
        ),
      ),
    );
  }
}

/// shows while something is dragged, dropping on it removes it.
class DeleteArea extends StatefulWidget {
  final bool over;

  const DeleteArea({required this.over, super.key});

  static const double size = 56;

  @override
  State<DeleteArea> createState() => _DeleteAreaState();
}

class _DeleteAreaState extends State<DeleteArea> {
  @override
  void didUpdateWidget(covariant DeleteArea oldWidget) {
    if (oldWidget.over != widget.over) customHapticFeedback();

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Semantics(
      label: scope.texts.delete,
      child: AnimatedScale(
        scale: widget.over ? 1.25 : 1,
        duration: MediaQuery.maybeDisableAnimationsOf(context) == true
            ? Duration.zero
            : const Duration(milliseconds: 150),
        child: Container(
          width: DeleteArea.size,
          height: DeleteArea.size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: scope.theme.surface),
          child: Icon(Icons.delete_outline_rounded, color: scope.theme.onSurface),
        ),
      ),
    );
  }
}
