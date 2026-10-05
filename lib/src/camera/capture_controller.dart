import 'dart:async';

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
  final ValueNotifier<double> minZoom = ValueNotifier(1);
  final ValueNotifier<double> maxZoom = ValueNotifier(1);
  final ValueNotifier<double> zoom = ValueNotifier(1);

  /// seconds before a capture, 0 is off.
  final ValueNotifier<int> timer = ValueNotifier(0);

  /// seconds left, null when not counting.
  final ValueNotifier<int?> countdown = ValueNotifier(null);
  Timer? _countdown;

  // a pinch asks many times a second, only one call goes to the camera at a time
  bool _zooming = false;
  double? _nextZoom;

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
    _readZoom(service);
    state.value = CaptureState.ready;
  }

  void _readZoom(CameraService service) {
    minZoom.value = service.minZoom;
    maxZoom.value = service.maxZoom;
    zoom.value = 1.0.clamp(service.minZoom, service.maxZoom);
  }

  /// the level shows right away, the camera follows with the latest one.
  Future<void> setZoom(double level) async {
    final service = this.service;
    if (service == null) return;
    zoom.value = level.clamp(minZoom.value, maxZoom.value);
    if (_zooming) {
      _nextZoom = zoom.value;
      return;
    }
    _zooming = true;
    try {
      double? next = zoom.value;
      while (next != null) {
        _nextZoom = null;
        await service.setZoom(next);
        next = _nextZoom;
      }
    } finally {
      _zooming = false;
    }
  }

  void cycleTimer() => timer.value = switch (timer.value) {
    0 => 3,
    3 => 10,
    _ => 0,
  };

  /// counts [timer] seconds down, then runs [onEnd].
  void startCountdown(VoidCallback onEnd) {
    cancelCountdown();
    countdown.value = timer.value;
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = countdown.value! - 1;
      if (left > 0) {
        countdown.value = left;
        return;
      }
      cancelCountdown();
      onEnd();
    });
  }

  void cancelCountdown() {
    _countdown?.cancel();
    _countdown = null;
    countdown.value = null;
  }

  Future<void> switchCamera() async {
    final service = this.service;
    if (service == null || state.value != CaptureState.ready || cameraCount.value < 2) return;
    cancelCountdown();
    await service.switchCamera();
    _front = !_front;
    hasFlash.value = service.hasFlash;
    flash.value = false;
    _readZoom(service);
  }

  Future<void> toggleFlash() async {
    final service = this.service;
    if (service == null || !hasFlash.value) return;
    flash.value = !flash.value;
    await service.setFlash(flash.value);
  }

  Future<void> focus(Offset point) async {
    await service?.focus(point);
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
    cancelCountdown();
    final service = _service;
    _service = null;
    state.value = CaptureState.initializing;
    service?.dispose();
  }

  void dispose() {
    _disposed = true;
    _countdown?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _service?.dispose();
    for (final notifier in [
      state,
      cameraCount,
      hasFlash,
      flash,
      microphone,
      minZoom,
      maxZoom,
      zoom,
      timer,
      countdown,
    ]) {
      notifier.dispose();
    }
  }
}
