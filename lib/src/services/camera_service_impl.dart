import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart' as cam;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class CameraServiceImpl implements CameraService {
  /// android can't open the camera while the last page's one is still closing.
  static Future<void> _closing = Future.value();

  List<cam.CameraDescription> _cameras = const [];
  cam.CameraController? _controller;
  int _index = 0;
  bool _microphone = true;
  double _minZoom = 1;
  double _maxZoom = 1;

  static const double maxZoomCap = 10;

  cam.CameraController get _camera => _controller!;

  @override
  Future<int> init({bool front = false}) async {
    // a page leaving in this same frame starts closing its camera only after this runs
    await Future<void>.value();
    await _closing;
    _cameras = await cam.availableCameras();
    if (_cameras.isEmpty) throw const CameraException(CameraFailure.noCamera);
    final lens = front ? cam.CameraLensDirection.front : cam.CameraLensDirection.back;
    _index = max(0, _cameras.indexWhere((camera) => camera.lensDirection == lens));
    try {
      _controller = await _open(audio: true);
    } on cam.CameraException catch (error) {
      if (!error.code.startsWith("AudioAccess")) throw _failure(error);
      // no microphone still allows photos and silent videos
      _microphone = false;
      try {
        _controller = await _open(audio: false);
      } on cam.CameraException catch (error) {
        throw _failure(error);
      }
    }
    await _readZoom();
    return _cameras.length;
  }

  Future<void> _readZoom() async {
    _minZoom = await _camera.getMinZoomLevel();
    _maxZoom = max(_minZoom, min(await _camera.getMaxZoomLevel(), maxZoomCap));
  }

  Future<cam.CameraController> _open({required bool audio}) async {
    final controller = cam.CameraController(_cameras[_index], cam.ResolutionPreset.high, enableAudio: audio);
    try {
      await controller.initialize();
    } catch (_) {
      // camerax can throw again closing a camera that never opened, that would hide the first error
      await controller.dispose().catchError((Object _) {});
      rethrow;
    }
    return controller;
  }

  static Object _failure(cam.CameraException error) =>
      error.code.startsWith("CameraAccess") ? const CameraException(CameraFailure.denied) : error;

  @override
  bool get hasMicrophone => _microphone;

  @override
  double get aspectRatio => _camera.value.aspectRatio;

  // the plugin turns its box by the sensor, which is wrong on an open foldable or a locked app.
  // a tight box makes its ratio give way
  @override
  Widget preview({required bool portrait, Widget? child}) => AspectRatio(
    aspectRatio: portrait ? 1 / aspectRatio : aspectRatio,
    child: cam.CameraPreview(_camera, child: child),
  );

  @override
  Future<void> switchCamera() async {
    _index = (_index + 1) % _cameras.length;
    await _camera.setDescription(_cameras[_index]);
    await _readZoom();
  }

  @override
  Future<void> setFlash(bool on) => _camera.setFlashMode(on ? cam.FlashMode.always : cam.FlashMode.off);

  @override
  Future<void> focus(Offset point) async {
    // the page can let the camera go while a focus is still going
    final camera = _controller;
    if (camera == null) return;
    final value = camera.value;
    // some android cameras say they support focus points then reject every one
    try {
      if (value.focusPointSupported) {
        await camera.setFocusMode(cam.FocusMode.auto);
        await camera.setFocusPoint(point);
      }
      if (value.exposurePointSupported) await camera.setExposurePoint(point);
    } on cam.CameraException catch (_) {}
  }

  // the camera plugin can't tell, but phones only have a flash on the back
  @override
  bool get hasFlash => _cameras[_index].lensDirection == cam.CameraLensDirection.back;

  @override
  double get minZoom => _minZoom;

  @override
  double get maxZoom => _maxZoom;

  @override
  Future<void> setZoom(double level) async {
    // a pinch keeps zooming after an await, when the page may have let the camera go
    await _controller?.setZoomLevel(level.clamp(_minZoom, _maxZoom));
  }

  @override
  Future<PickedItem> takePhoto() async {
    final file = await _camera.takePicture();
    // read by the engine, the photo never gets copied into dart memory just for its size
    final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final item = PickedItem(
      file: file,
      type: MediaType.image,
      width: descriptor.width,
      height: descriptor.height,
      edited: false,
    );
    descriptor.dispose();
    buffer.dispose();
    return item;
  }

  @override
  Future<void> startVideo() => _camera.startVideoRecording();

  @override
  Future<PickedItem> stopVideo() async {
    final file = await _camera.stopVideoRecording();
    // the video is recorded at the preview size, turned like the phone was held
    final size = _camera.value.previewSize ?? Size.zero;
    final portrait = switch (_camera.value.deviceOrientation) {
      DeviceOrientation.portraitUp || DeviceOrientation.portraitDown => true,
      _ => false,
    };
    final long = max(size.width, size.height).round();
    final short = min(size.width, size.height).round();
    return PickedItem(
      file: file,
      type: MediaType.video,
      width: portrait ? short : long,
      height: portrait ? long : short,
      edited: false,
    );
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    // a failed close would make every camera opened after it fail too
    if (controller != null) _closing = controller.dispose().catchError((Object _) {});
    await _closing;
  }
}
