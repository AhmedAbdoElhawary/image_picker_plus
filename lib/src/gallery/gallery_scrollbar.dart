import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// a draggable thumb on the end side with the date beside it, shown only while scrolling.
class GalleryScrollbar extends StatefulWidget {
  final ScrollController controller;

  /// the grid's padding over the first row, where the preview sits.
  final double top;

  /// how far the preview is slid up, the track grows into the room it gives back.
  final ValueListenable<double> collapse;

  /// the date at a 0 to 1 spot of the list, null shows no date.
  final String? Function(double fraction) label;
  final Widget child;

  const GalleryScrollbar({
    required this.controller,
    required this.top,
    required this.collapse,
    required this.label,
    required this.child,
    super.key,
  });

  @override
  State<GalleryScrollbar> createState() => _GalleryScrollbarState();
}

class _GalleryScrollbarState extends State<GalleryScrollbar> {
  static const Duration _hideDelay = Duration(seconds: 1);

  final ValueNotifier<bool> _visible = ValueNotifier(false);
  final ValueNotifier<bool> _dragging = ValueNotifier(false);
  Timer? _hide;

  // made once, the grid rebuilds this on every page it loads
  late final Listenable _changes = Listenable.merge([widget.controller, widget.collapse, _dragging]);

  @override
  void dispose() {
    _hide?.cancel();
    _visible.dispose();
    _dragging.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    // only the user's scroll, not a jump like the one to the top on album change
    if (notification is ScrollUpdateNotification && notification.dragDetails != null) _show();
    if (notification is ScrollEndNotification) _hideLater();
    return false;
  }

  void _show() {
    _hide?.cancel();
    _visible.value = true;
  }

  void _hideLater() {
    // the drag scrolls by jumps, each one ends a scroll
    if (_dragging.value) return;
    _hide?.cancel();
    _hide = Timer(_hideDelay, () => _visible.value = false);
  }

  void _endDrag() {
    _dragging.value = false;
    _hideLater();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          ListenableBuilder(
            listenable: _changes,
            builder: (context, _) {
              if (!controller.hasClients) return const SizedBox.shrink();
              final position = controller.position;
              if (!position.hasContentDimensions || position.maxScrollExtent <= 0)
                return const SizedBox.shrink();
              final top = max(0.0, widget.top - widget.collapse.value);
              final track = position.viewportDimension - top - PickerLayout.minTouch;
              if (track <= 0) return const SizedBox.shrink();
              final fraction = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
              return PositionedDirectional(
                end: 0,
                top: top + fraction * track,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _visible,
                  builder: (context, visible, child) => IgnorePointer(
                    ignoring: !visible,
                    child: AnimatedOpacity(
                      opacity: visible ? 1 : 0,
                      duration: PickerDurations.of(context).medium,
                      child: child,
                    ),
                  ),
                  child: GestureDetector(
                    onVerticalDragStart: (_) {
                      _dragging.value = true;
                      _show();
                    },
                    onVerticalDragUpdate: (details) => controller.jumpTo(
                      (position.pixels + details.delta.dy / track * position.maxScrollExtent).clamp(
                        0,
                        position.maxScrollExtent,
                      ),
                    ),
                    onVerticalDragEnd: (_) => _endDrag(),
                    onVerticalDragCancel: _endDrag,
                    child: _Thumb(label: widget.label(fraction), held: _dragging.value),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? label;

  /// the date shrinks a little and steps away from the edge while held.
  final bool held;

  const _Thumb({required this.label, required this.held});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final label = this.label;
    final away = Directionality.of(context) == TextDirection.ltr ? -12.0 : 12.0;
    return SizedBox(
      height: PickerLayout.minTouch,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            TweenAnimationBuilder<double>(
              tween: Tween(end: held ? 1 : 0),
              duration: PickerDurations.of(context).short,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(away * value, 0),
                child: Transform.scale(scale: 1 - 0.1 * value, child: child),
              ),
              child: DecoratedBox(
                decoration: ShapeDecoration(color: theme.surface, shape: const StadiumBorder()),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    label,
                    style: TextStyle(color: theme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: theme.background.withValues(alpha: 0.6),
                shape: const StadiumBorder(),
              ),
              child: const SizedBox(width: 6, height: 40),
            ),
          ),
        ],
      ),
    );
  }
}
