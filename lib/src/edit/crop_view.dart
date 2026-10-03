import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/crop_overlay.dart';
import 'package:image_picker_plus/src/edit/cropped_image.dart';

/// the crop window sits in the middle, dragging and pinching move the image under it.
class CropView extends StatefulWidget {
  final CropController controller;
  final Widget image;

  const CropView({required this.controller, required this.image, super.key});

  @override
  State<CropView> createState() => _CropViewState();
}

class _CropViewState extends State<CropView> with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _moving = ValueNotifier(false);
  double _startZoom = 1;

  /// the drag past the image edge, normalized like the rect, before the rubber band.
  final ValueNotifier<Offset> _overscroll = ValueNotifier(Offset.zero);
  Offset _bounceFrom = Offset.zero;
  late final AnimationController _bounce = AnimationController(vsync: this)
    ..addListener(() {
      final t = Curves.easeOutCubic.transform(_bounce.value);
      _overscroll.value = Offset.lerp(_bounceFrom, Offset.zero, t)!;
    });

  @override
  void dispose() {
    _bounce.dispose();
    _moving.dispose();
    _overscroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final scope = PickerScope.of(context);

    return LayoutBuilder(
      // only a ratio change moves the window, panning and zooming rebuild just the image below
      builder: (context, constraints) => Selector<double>(
        listenable: controller,
        select: () => controller.aspect,
        builder: (context, aspect, _) {
          final window = _window(constraints.biggest, aspect);
          return Listener(
            onPointerSignal: (event) => GestureBinding.instance.pointerSignalResolver.register(
              event,
              (event) => _onSignal(event, window),
            ),
            child: GestureDetector(
              onScaleStart: (_) {
                _bounce.stop();
                _moving.value = true;
                _startZoom = controller.zoom;
              },
              onScaleUpdate: (details) {
                var rect = controller.value;
                if (details.pointerCount > 1) {
                  final focal = details.localFocalPoint - window.topLeft;
                  controller.zoomTo(
                    _startZoom * details.scale,
                    focal: Offset(
                      rect.left + focal.dx / window.width * rect.width,
                      rect.top + focal.dy / window.height * rect.height,
                    ),
                  );
                  rect = controller.value;
                }
                final delta = details.focalPointDelta;
                // overscroll is given back first, so dragging back toward the image undoes it before panning
                final move =
                    _overscroll.value +
                    Offset(-delta.dx / window.width * rect.width, -delta.dy / window.height * rect.height);
                controller.pan(move);
                _overscroll.value = move - (controller.value.topLeft - rect.topLeft);
              },
              onScaleEnd: (_) {
                _moving.value = false;
                if (_overscroll.value == Offset.zero) return;
                _bounceFrom = _overscroll.value;
                _bounce.duration = PickerDurations.of(context).long;
                _bounce.forward(from: 0);
              },
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fromRect(
                      rect: window,
                      child: ColoredBox(
                        color: scope.theme.surface,
                        child: ListenableBuilder(
                          listenable: Listenable.merge([controller, _overscroll]),
                          builder: (context, image) {
                            final rect = controller.value;
                            final overscroll = _overscroll.value;
                            return CroppedImage(
                              rect: rect.shift(
                                Offset(
                                  _rubber(overscroll.dx, rect.width),
                                  _rubber(overscroll.dy, rect.height),
                                ),
                              ),
                              clip: false,
                              child: image!,
                            );
                          },
                          child: widget.image,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _moving,
                      builder: (context, moving, _) => CropOverlay(window: window, showGrid: moving),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// mouse wheel and web trackpad, desktop trackpads already come in as pan-zoom through the scale handlers.
  void _onSignal(PointerSignalEvent event, Rect window) {
    final controller = widget.controller;
    final rect = controller.value;
    final local = event.localPosition - window.topLeft;
    final focal = Offset(
      rect.left + local.dx / window.width * rect.width,
      rect.top + local.dy / window.height * rect.height,
    );
    if (event is PointerScaleEvent) {
      controller.zoomTo(controller.zoom * event.scale, focal: focal);
    } else if (event is PointerScrollEvent && event.kind == PointerDeviceKind.trackpad) {
      final delta = event.scrollDelta;
      controller.pan(Offset(delta.dx / window.width * rect.width, delta.dy / window.height * rect.height));
    } else if (event is PointerScrollEvent) {
      controller.zoomTo(controller.zoom * exp(-event.scrollDelta.dy / 200), focal: focal);
    }
  }

  /// same resistance curve as ios scroll views, it never goes past [size].
  static double _rubber(double offset, double size) {
    if (offset == 0) return 0;
    return offset.sign * (1 - 1 / (offset.abs() * 0.55 / size + 1)) * size;
  }

  /// the biggest rect with the crop aspect, centered.
  static Rect _window(Size box, double aspect) {
    var width = box.width;
    var height = width / aspect;
    if (height > box.height) {
      height = box.height;
      width = height * aspect;
    }
    return Rect.fromCenter(center: box.center(Offset.zero), width: width, height: height);
  }
}
