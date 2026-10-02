import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';

enum CaptureState { initializing, ready, recording, noCamera, denied }

class CaptureController with WidgetsBindingObserver {
  /// a new service each time, since a paused app gives the camera back.
  final CameraService Function() create;

  final ValueNotifier<CaptureState> state = ValueNotifier(CaptureState.initializing);
  final ValueNotifier<int> cameraCount = ValueNotifier(0);
  final ValueNotifier<bool> hasFlash = ValueNotifier(false);
  final ValueNotifier<bool> flash = ValueNotifier(false);
  final ValueNotifier<bool> microphone = ValueNotifier(true);

  CameraService? _service;
  bool _front = false;
  bool _busy = false;
  bool _disposed = false;

  CaptureController({required this.create}) {
    WidgetsBinding.instance.addObserver(this);
  }

  CameraService? get service =>
      state.value == CaptureState.ready || state.value == CaptureState.recording ? _service : null;

  Future<void> init() async {
    state.value = CaptureState.initializing;
    final service = create();
    _service = service;
    try {
      cameraCount.value = await service.init(front: _front);
    } on CameraException catch (error) {
      if (_disposed) return;
      state.value = error.failure == CameraFailure.noCamera ? CaptureState.noCamera : CaptureState.denied;
      return;
    }
    if (_disposed || _service != service) {
      await service.dispose();
      return;
    }
    microphone.value = service.hasMicrophone;
    hasFlash.value = service.hasFlash;
    flash.value = false;
    state.value = CaptureState.ready;
  }

  Future<void> switchCamera() async {
    final service = this.service;
    if (service == null || state.value != CaptureState.ready || cameraCount.value < 2) return;
    await service.switchCamera();
    _front = !_front;
    hasFlash.value = service.hasFlash;
    flash.value = false;
  }

  Future<void> toggleFlash() async {
    final service = this.service;
    if (service == null || !hasFlash.value) return;
    flash.value = !flash.value;
    await service.setFlash(flash.value);
  }

  Future<PickedItem?> takePhoto() => _once((service) => service.takePhoto());

  /// the video when it stops, null when it starts.
  Future<PickedItem?> toggleRecording() => _once((service) async {
    if (state.value == CaptureState.recording) {
      final item = await service.stopVideo();
      state.value = CaptureState.ready;
      return item;
    }
    await service.startVideo();
    state.value = CaptureState.recording;
    return null;
  });

  // a fast double tap would ask the camera twice at once
  Future<PickedItem?> _once(Future<PickedItem?> Function(CameraService service) action) async {
    final service = this.service;
    if (service == null || _busy) return null;
    _busy = true;
    try {
      return await action(service);
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final current = this.state.value;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (current == CaptureState.ready || current == CaptureState.recording) _release();
    } else if (state == AppLifecycleState.resumed &&
        current == CaptureState.initializing &&
        _service == null) {
      init();
    }
  }

  void _release() {
    final service = _service;
    _service = null;
    state.value = CaptureState.initializing;
    service?.dispose();
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _service?.dispose();
    for (final notifier in [state, cameraCount, hasFlash, flash, microphone]) {
      notifier.dispose();
    }
  }
}
