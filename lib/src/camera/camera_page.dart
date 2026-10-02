import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/camera_controls.dart';
import 'package:image_picker_plus/src/camera/capture_button.dart';
import 'package:image_picker_plus/src/camera/capture_controller.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_route.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

class CameraPage extends StatefulWidget {
  final bool video;

  const CameraPage({required this.video, super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CaptureController? _controller;

  /// the last photo's edits, kept until the next photo since the edit page uses them while it closes.
  CropController? _crop;
  ValueNotifier<int>? _filterIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _controller = CaptureController(create: PickerScope.of(context).services.camera)..init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _crop?.dispose();
    _filterIndex?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller!;
    final item = widget.video ? await controller.toggleRecording() : await controller.takePhoto();
    if (item == null || !mounted) return;
    final scope = PickerScope.of(context);
    final settings = scope.settings;
    if (item.type == MediaType.image && settings.editing) {
      final photo = MediaItem(
        id: item.file.path,
        type: MediaType.image,
        width: item.width,
        height: item.height,
        modified: DateTime.now(),
        path: item.file.path,
      );
      _crop?.dispose();
      _filterIndex?.dispose();
      final crop = _crop = settings.cropRatios.isEmpty
          ? null
          : CropController(
              imageAspect: item.height == 0 ? 1 : item.width / item.height,
              ratio: settings.cropRatios.first,
            );
      final filterIndex = _filterIndex = settings.filters ? ValueNotifier(0) : null;
      final items = await Navigator.of(context).push<List<PickedItem>>(
        PickerRoute(
          context: context,
          builder: (_) => scope.wrap(
            EditPage(
              items: [photo],
              crops: {photo.id: ?crop},
              filterIndexes: {photo.id: ?filterIndex},
              changeRatio: true,
            ),
          ),
        ),
      );
      if (items != null && mounted) Navigator.of(context).pop(items);
      return;
    }
    Navigator.of(context).pop([item]);
  }

  void _close() => Navigator.of(context).pop();

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
            onClose: _close,
          ),
          CaptureState.denied => MessageView(
            scope.texts.cameraDenied,
            key: const ValueKey(CaptureState.denied),
            onClose: _close,
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
                    PickerAppBar(color: scope.theme.background.withValues(alpha: 0.6), onClose: _close),
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
            child: AspectRatio(aspectRatio: service.aspectRatio, child: service.preview()),
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
        if (microphone) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: PickerLayout.padding / 2),
          child: Text(scope.texts.noMicrophone, style: TextStyle(color: scope.theme.onSurfaceMuted)),
        );
      },
    );
  }
}
