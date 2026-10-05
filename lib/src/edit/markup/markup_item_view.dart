import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';

/// a text or sticker the user can move, pinch, twist or tap. it's drawn by the layer under it, this only takes the touches.
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
    StickerMark() => item.copyWith(width: item.width.clamp(_minSide / size.width, 3.0)),
    StrokeMark() => item,
  };

  static const double _minSide = 24;

  @override
  State<MarkupItemView> createState() => _MarkupItemViewState();
}

class _MarkupItemViewState extends State<MarkupItemView> {
  MarkupItem? _start;
  MarkupItem? _now;
  Offset _from = Offset.zero;
  Offset _pointer = Offset.zero;

  MarkupItem _moved(MarkupItem start, Offset delta, double scale, double rotation) {
    final shift = Offset(delta.dx / widget.size.width, delta.dy / widget.size.height);
    final next = switch (start) {
      TextMark() => start.copyWith(
        center: start.center + shift,
        size: start.size * scale,
        angle: start.angle + rotation,
      ),
      StickerMark() => start.copyWith(
        center: start.center + shift,
        width: start.width * scale,
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
      StickerMark() => (item.center, item.angle),
      StrokeMark() => (Offset.zero, 0.0),
    };
    final box = MarkupPainter.measure(item, widget.size, const {});
    final width = max(box.width, PickerLayout.minTouch);
    final height = max(box.height, PickerLayout.minTouch);
    return Positioned(
      left: center.dx * widget.size.width - width / 2,
      top: center.dy * widget.size.height - height / 2,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: angle,
        child: Listener(
          onPointerSignal: (event) => GestureBinding.instance.pointerSignalResolver.register(event, _signal),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onScaleStart: (details) {
              _start = _now = item;
              _from = _pointer = details.focalPoint;
            },
            onScaleUpdate: (details) {
              final start = _start;
              if (start == null) return;
              _pointer = details.focalPoint;
              final now = _now = _moved(start, details.focalPoint - _from, details.scale, details.rotation);
              widget.onMove(now, _pointer);
            },
            onScaleEnd: (_) {
              final now = _now;
              _start = _now = null;
              if (now != null) widget.onEnd(now, _pointer);
            },
          ),
        ),
      ),
    );
  }
}

/// shows while something is dragged, dropping on it removes it.
class DeleteArea extends StatelessWidget {
  final bool over;

  const DeleteArea({required this.over, super.key});

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Semantics(
      label: scope.texts.delete,
      child: AnimatedScale(
        scale: over ? 1.25 : 1,
        duration: MediaQuery.maybeDisableAnimationsOf(context) == true
            ? Duration.zero
            : const Duration(milliseconds: 150),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: scope.theme.scrim),
          child: Icon(Icons.delete_outline_rounded, color: scope.theme.onSurface),
        ),
      ),
    );
  }
}
