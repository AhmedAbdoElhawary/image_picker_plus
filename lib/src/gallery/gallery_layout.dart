import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/selector.dart';

/// preview above the grid on phones, beside it on wide screens.
/// on phones scrolling the grid slides the preview up, leaving a strip to drag it back down.
class GalleryLayout extends StatefulWidget {
  /// null when the preview is off.
  final Widget? preview;

  /// [padding] keeps the first row out from under the preview, [collapse] is how far it's slid up.
  final Widget Function(EdgeInsetsGeometry padding, ValueListenable<double> collapse) grid;

  /// shows the whole preview again when it notifies, like when an image is tapped.
  final Listenable reveal;

  const GalleryLayout({required this.preview, required this.grid, required this.reveal, super.key});

  @override
  State<GalleryLayout> createState() => _GalleryLayoutState();
}

class _GalleryLayoutState extends State<GalleryLayout> with SingleTickerProviderStateMixin {
  /// how far the preview is slid up.
  final ValueNotifier<double> _collapse = ValueNotifier(0);
  double _maxCollapse = 0;
  late final AnimationController _snap = AnimationController.unbounded(vsync: this)
    ..addListener(() => _collapse.value = _snap.value);

  @override
  void initState() {
    super.initState();
    widget.reveal.addListener(_reveal);
  }

  @override
  void didUpdateWidget(GalleryLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reveal == widget.reveal) return;
    oldWidget.reveal.removeListener(_reveal);
    widget.reveal.addListener(_reveal);
  }

  @override
  void dispose() {
    widget.reveal.removeListener(_reveal);
    _snap.dispose();
    _collapse.dispose();
    super.dispose();
  }

  void _reveal() {
    if (_collapse.value > 0) _animateTo(0);
  }

  void _animateTo(double target) {
    _snap.value = _collapse.value;
    _snap.animateTo(target, duration: PickerDurations.of(context).medium, curve: Curves.easeOutCubic);
  }

  bool _onScroll(ScrollUpdateNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) return false;
    _snap.stop();
    final delta = notification.scrollDelta ?? 0;
    // up slides it with the grid, down leaves it until the grid is back near the top
    final next = delta > 0 ? _collapse.value + delta : min(_collapse.value, notification.metrics.pixels);
    _collapse.value = next.clamp(0, _maxCollapse);
    return false;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final open = velocity > 300 || (velocity > -300 && _collapse.value < _maxCollapse / 2);
    _animateTo(open ? 0 : _maxCollapse);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    if (preview == null) return widget.grid(EdgeInsets.zero, _collapse);
    if (PickerLayout.of(context).previewBeside) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(PickerLayout.padding),
              child: ClipRRect(borderRadius: BorderRadius.circular(PickerLayout.radius), child: preview),
            ),
          ),
          Expanded(child: widget.grid(EdgeInsets.zero, _collapse)),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // square, but never more than half the height so the grid stays usable
        final height = min(constraints.maxWidth, constraints.maxHeight / 2);
        _maxCollapse = max(0, height - PickerLayout.minTouch);
        return ClipRect(
          child: Stack(
            children: [
              NotificationListener<ScrollUpdateNotification>(
                onNotification: _onScroll,
                child: widget.grid(EdgeInsetsDirectional.only(top: height + PickerLayout.gap), _collapse),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height,
                child: ValueListenableBuilder<double>(
                  valueListenable: _collapse,
                  builder: (context, collapse, child) =>
                      Transform.translate(offset: Offset(0, -min(collapse, _maxCollapse)), child: child),
                  // while slid up the strip only drags or taps it back, the crop under it stays still
                  child: Selector<bool>(
                    listenable: _collapse,
                    select: () => _collapse.value > 0,
                    builder: (context, collapsed, _) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: collapsed ? _reveal : null,
                      onVerticalDragStart: collapsed ? (_) => _snap.stop() : null,
                      onVerticalDragUpdate: collapsed
                          ? (details) => _collapse.value = (_collapse.value - details.delta.dy).clamp(0, _maxCollapse)
                          : null,
                      onVerticalDragEnd: collapsed ? _onDragEnd : null,
                      child: AbsorbPointer(absorbing: collapsed, child: preview),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
