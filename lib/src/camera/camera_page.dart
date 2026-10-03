import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/camera_controls.dart';
import 'package:image_picker_plus/src/camera/capture_button.dart';
import 'package:image_picker_plus/src/camera/capture_controller.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

class CameraPage extends StatefulWidget {
  final bool video;

  /// while adding from the edit page, close goes back to it.
  final bool adding;
  final ValueChanged<PickedItem> onTaken;
  final VoidCallback onClose;

  const CameraPage({required this.video, required this.onTaken, required this.onClose, this.adding = false, super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CaptureController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _controller = CaptureController(create: PickerScope.of(context).services.camera)..init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller!;
    final item = widget.video ? await controller.toggleRecording() : await controller.takePhoto();
    if (item != null && mounted) widget.onTaken(item);
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final controller = _controller!;
    return Selector<CaptureState>(
      listenable: controller.state,
      // initializing, ready and recording share one screen, its parts listen for themselves
      select: () => switch (controller.state.value) {
        CaptureState.noCamera || CaptureState.denied => controller.state.value,
        _ => CaptureState.ready,
      },
      builder: (context, state, _) => AnimatedSwitcher(
        duration: PickerDurations.of(context).medium,
        child: switch (state) {
          CaptureState.noCamera => MessageView(
            scope.texts.noCamera,
            key: const ValueKey(CaptureState.noCamera),
            onClose: widget.onClose,
          ),
          CaptureState.denied => MessageView(
            scope.texts.cameraDenied,
            key: const ValueKey(CaptureState.denied),
            onClose: widget.onClose,
            actionText: scope.texts.openSettings,
            onAction: scope.services.gallery!.openSettings,
          ),
          _ => SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - (PickerLayout.pickerTabsHeight),

              child: Material(
                key: const ValueKey(CaptureState.ready),
                color: scope.theme.background,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    _Preview(controller: controller),
                    PickerAppBar(
                      color: scope.theme.background.withValues(alpha: 0.6),
                      closeIcon: widget.adding ? Icons.arrow_back_rounded : Icons.close_rounded,
                      onClose: widget.onClose,
                    ),
                    Selector<CameraService?>(
                      listenable: controller.state,
                      select: () => controller.service,
                      builder: (context, service, child) {
                        if (service == null) return const SizedBox.shrink();
                        return child ?? const SizedBox.shrink();
                      },
                      child: ColoredBox(
                        color: scope.theme.background.withValues(alpha: 0.6),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(vertical: PickerLayout.padding * 2.47),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.video) _MicrophoneNote(controller: controller),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FlashButton(controller: controller),
                                  ValueListenableBuilder<CaptureState>(
                                    valueListenable: controller.state,
                                    builder: (context, state, _) => CaptureButton(
                                      video: widget.video,
                                      recording: state == CaptureState.recording,
                                      onTap: state == CaptureState.initializing ? null : _capture,
                                    ),
                                  ),
                                  SwitchCameraButton(controller: controller),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final CaptureController controller;

  const _Preview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);

    return Selector<CameraService?>(
      listenable: controller.state,
      select: () => controller.service,
      builder: (context, service, _) {
        if (service == null) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: scope.theme.onSurface));
        }

        return Align(
          alignment: AlignmentDirectional.topCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PickerLayout.radius),
            child: AspectRatio(
              aspectRatio: service.aspectRatio,
              child: _FocusArea(controller: controller, child: service.preview()),
            ),
          ),
        );
      },
    );
  }
}

/// tap to focus there, a ring shows where.
class _FocusArea extends StatefulWidget {
  final CaptureController controller;
  final Widget child;

  const _FocusArea({required this.controller, required this.child});

  @override
  State<_FocusArea> createState() => _FocusAreaState();
}

class _FocusAreaState extends State<_FocusArea> {
  Offset? _point;

  /// a new ring for each tap, so it starts over.
  int _taps = 0;

  void _focus(TapUpDetails details) {
    final size = context.size!;
    final point = details.localPosition;
    widget.controller.focus(Offset(point.dx / size.width, point.dy / size.height));
    setState(() {
      _point = point;
      _taps++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _focus,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          // not directional, the tap is from the left in rtl too
          if (point != null)
            Positioned(
              left: point.dx - _FocusRing.size / 2,
              top: point.dy - _FocusRing.size / 2,
              child: _FocusRing(key: ValueKey(_taps), onEnd: () => setState(() => _point = null)),
            ),
        ],
      ),
    );
  }
}

/// shrinks in, stays a moment, then fades out.
class _FocusRing extends StatelessWidget {
  static const double size = 64;

  final VoidCallback onEnd;

  const _FocusRing({required this.onEnd, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final grow = MediaQuery.maybeDisableAnimationsOf(context) == true ? 0.0 : 0.25;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 1),
        onEnd: onEnd,
        builder: (context, t, child) => Opacity(
          opacity: 1 - const Interval(0.7, 1).transform(t),
          child: Transform.scale(
            scale: 1 + grow * (1 - const Interval(0, 0.3, curve: Curves.easeOut).transform(t)),
            child: child,
          ),
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.onSurface, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _MicrophoneNote extends StatelessWidget {
  final CaptureController controller;

  const _MicrophoneNote({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: controller.microphone,
      builder: (context, microphone, _) {
        if (microphone) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: PickerLayout.padding / 2),
          child: Text(scope.texts.noMicrophone, style: TextStyle(color: scope.theme.onSurfaceMuted)),
        );
      },
    );
  }
}
