import 'dart:math';
import 'dart:ui' show DisplayFeatureType;

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
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
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
  final GlobalKey _area = GlobalKey();
  final GlobalKey _stream = GlobalKey();

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
      final taken = widget.video ? await controller.toggleRecording() : await controller.takePhoto();
      item = taken == null || widget.video || !mounted ? taken : await _seenOnly(taken);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(PickerScope.of(context).texts.somethingWentWrong)));
      return;
    }
    if (item != null && mounted) widget.onTaken(item);
  }

  /// a covered preview cuts the image's edges, the photo is cut the same so it's what was seen.
  /// videos can't be cut without re-encoding them, so they keep their edges.
  Future<PickedItem> _seenOnly(PickedItem item) async {
    final box = _area.currentContext?.size;
    final stream = _stream.currentContext?.size;
    if (box == null ||
        stream == null ||
        box.isEmpty ||
        stream.isEmpty ||
        item.width == 0 ||
        item.height == 0) {
      return item;
    }
    final image = item.width / item.height;
    final shown = stream.aspectRatio;
    final seen = box.aspectRatio;
    // the preview can be the middle of a photo of another shape, and what's seen is the middle of the preview
    final rect = Rect.fromCenter(
      center: const Offset(0.5, 0.5),
      width: min(1.0, shown / image) * min(1.0, seen / shown),
      height: min(1.0, image / shown) * min(1.0, shown / seen),
    );
    if (rect.width > 0.99 && rect.height > 0.99) return item;
    final scope = PickerScope.of(context);
    final cut = await scope.services.image.export(
      item.file,
      EditState(cropRect: rect),
      PickerFilter.identity,
      scope.settings.output,
    );
    return cut.copyWith(edited: false);
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final camera = scope.settings.camera;
    final controller = _controller!;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final fill = landscape || MediaQuery.sizeOf(context).shortestSide >= PickerLayout.tabletSide;
    final bar = scope.theme.background.withValues(alpha: 0.6);
    // a row under the preview, or a column beside it when there's little height, with the timer and grid in it
    final buttons = Flex(
      direction: landscape ? Axis.vertical : Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: landscape ? CrossAxisAlignment.center : CrossAxisAlignment.end,
      children: [
        if (landscape && camera.grid) GridButton(grid: _grid),
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
        if (landscape && camera.timer) TimerButton(controller: controller),
      ],
    );
    final notes = [
      if (camera.zoomButtons) ZoomButtons(controller: controller),
      if (widget.video) _MicrophoneNote(controller: controller),
    ];
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
                    _Preview(controller: controller, grid: _grid, fill: fill, area: _area, stream: _stream),
                    PickerAppBar(
                      color: scope.theme.background.withValues(alpha: 0.6),
                      closeIcon: widget.adding ? CloseButtonEnum.back : CloseButtonEnum.close,
                      onClose: widget.onClose,
                    ),
                    if (!landscape && (camera.timer || camera.grid))
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
                      child: landscape
                          ? Positioned.fill(
                              child: Stack(
                                children: [
                                  // over the top bar too, a short phone on its side needs the whole height
                                  PositionedDirectional(
                                    top: 0,
                                    end: 0,
                                    bottom: 0,
                                    child: ColoredBox(
                                      color: bar,
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional.symmetric(
                                          horizontal: PickerLayout.padding / 2,
                                        ),
                                        child: buttons,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(bottom: PickerLayout.padding),
                                      child: Column(mainAxisSize: MainAxisSize.min, children: notes),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ColoredBox(
                              color: bar,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  bottom: PickerLayout.padding * 2.47,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [...notes, buttons],
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

  /// covers the space and cuts the image's edges, instead of fitting it at the top.
  final bool fill;

  /// on the covered space, the photo is cut to its size.
  final GlobalKey area;

  /// on the whole preview, of which [area] shows the middle.
  final GlobalKey stream;

  const _Preview({
    required this.controller,
    required this.grid,
    required this.fill,
    required this.area,
    required this.stream,
  });

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
        final overlay = scope.settings.camera.overlay;
        final size = MediaQuery.sizeOf(context);
        // an open foldable's camera sits on one half, so its image has that half's shape.
        // the plugin only knows the screen is on its side and stretches it
        final fold = MediaQuery.displayFeaturesOf(
          context,
        ).where((feature) => feature.type != DisplayFeatureType.cutout).firstOrNull;
        final across = fold != null && fold.bounds.height >= fold.bounds.width;
        final portrait = fold == null
            ? size.height >= size.width
            : (across ? size.height > size.width / 2 : size.height / 2 > size.width);
        // none of it takes taps, and none of it is in the photo
        final layers = Stack(
          fit: StackFit.expand,
          children: [
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
        );

        if (!fill) {
          return Align(
            alignment: AlignmentDirectional.topCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PickerLayout.radius),
              child: service.preview(
                portrait: portrait,
                child: FocusArea(controller: controller, child: layers),
              ),
            ),
          );
        }
        return LayoutBuilder(
          key: area,
          builder: (context, constraints) {
            final box = constraints.biggest;
            final ratio = portrait ? 1 / service.aspectRatio : service.aspectRatio;
            final cover = box.aspectRatio > ratio
                ? Size(box.width, box.width / ratio)
                : Size(box.height * ratio, box.height);
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: OverflowBox(
                    minWidth: cover.width,
                    maxWidth: cover.width,
                    minHeight: cover.height,
                    maxHeight: cover.height,
                    child: KeyedSubtree(
                      key: stream,
                      child: service.preview(
                        portrait: portrait,
                        child: FocusArea(controller: controller, child: const SizedBox.expand()),
                      ),
                    ),
                  ),
                ),
                // on what's seen, so the grid and the frame match the cut photo
                layers,
              ],
            );
          },
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
