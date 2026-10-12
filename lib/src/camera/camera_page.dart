import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/camera_controls.dart';
import 'package:image_picker_plus/src/camera/camera_tools.dart';
import 'package:image_picker_plus/src/camera/capture_button.dart';
import 'package:image_picker_plus/src/camera/capture_controller.dart';
import 'package:image_picker_plus/src/camera/focus_area.dart';
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

  const CameraPage({
    required this.video,
    required this.onTaken,
    required this.onClose,
    this.adding = false,
    super.key,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CaptureController? _controller;
  late final ValueNotifier<bool> _grid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = PickerScope.of(context);
    _controller = CaptureController(create: scope.services.camera)..init();
    _grid = ValueNotifier(scope.settings.camera.gridOn);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _grid.dispose();
    super.dispose();
  }

  /// a tap while counting stops it, stopping a recording never waits for the timer.
  void _capture() {
    final controller = _controller!;
    if (controller.countdown.value != null) return controller.cancelCountdown();
    final recording = controller.state.value == CaptureState.recording;
    if (controller.timer.value > 0 && !recording) return controller.startCountdown(_captureNow);
    _captureNow();
  }

  Future<void> _captureNow() async {
    final controller = _controller!;
    final PickedItem? item;
    try {
      item = widget.video ? await controller.toggleRecording() : await controller.takePhoto();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(PickerScope.of(context).texts.somethingWentWrong)));
      return;
    }
    if (item != null && mounted) widget.onTaken(item);
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final camera = scope.settings.camera;
    final controller = _controller!;
    return Selector<CaptureState>(
      listenable: controller.state,
      // initializing, ready and recording share one screen, its parts listen for themselves
      select: () => switch (controller.state.value) {
        CaptureState.noCamera || CaptureState.denied || CaptureState.failed => controller.state.value,
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
          CaptureState.failed => MessageView(
            scope.texts.somethingWentWrong,
            key: const ValueKey(CaptureState.failed),
            onClose: widget.onClose,
            actionText: scope.texts.tryAgain,
            onAction: controller.init,
          ),
          _ => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height - (PickerLayout.pickerTabsHeight),

              // a scaffold so a failed capture can show its snackbar here
              child: Scaffold(
                key: const ValueKey(CaptureState.ready),
                backgroundColor: scope.theme.background,
                body: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    _Preview(controller: controller, grid: _grid),
                    PickerAppBar(
                      color: scope.theme.background.withValues(alpha: 0.6),
                      closeIcon: widget.adding ? CloseButtonEnum.back : CloseButtonEnum.close,
                      onClose: widget.onClose,
                    ),
                    if (camera.timer || camera.grid)
                      Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scope.theme.background.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.all(Radius.circular(50)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (camera.timer) TimerButton(controller: controller),
                                if (camera.grid) GridButton(grid: _grid),
                              ],
                            ),
                          ),
                        ),
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
                          padding: const EdgeInsetsDirectional.only(bottom: PickerLayout.padding * 2.47),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (camera.zoomButtons) ZoomButtons(controller: controller),
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
  final ValueNotifier<bool> grid;

  const _Preview({required this.controller, required this.grid});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);

    return Selector<CameraService?>(
      listenable: controller.state,
      select: () => controller.service,
      builder: (context, service, _) {
        final overlay = scope.settings.camera.overlay;
        if (service == null) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: scope.theme.onSurface));
        }

        return Align(
          alignment: AlignmentDirectional.topCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PickerLayout.radius),
            child: AspectRatio(
              aspectRatio: service.aspectRatio,
              child: FocusArea(
                controller: controller,
                // all of it over the preview, never in the photo, and none of it takes taps
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    service.preview(),
                    ValueListenableBuilder<bool>(
                      valueListenable: grid,
                      builder: (context, on, _) => on ? const GridLines() : const SizedBox.shrink(),
                    ),
                    if (overlay != null)
                      IgnorePointer(
                        child: LayoutBuilder(
                          builder: (context, constraints) => overlay(context, constraints.biggest),
                        ),
                      ),
                    Countdown(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          ),
          child: microphone
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: PickerLayout.padding * 0.4),
                  child: Text(
                    scope.texts.noMicrophone,
                    style: TextStyle(color: scope.theme.onSurfaceMuted, fontWeight: FontWeight.w500),
                  ),
                ),
        );
      },
    );
  }
}
