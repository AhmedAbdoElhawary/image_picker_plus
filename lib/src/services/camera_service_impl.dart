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
    return _cameras.length;
  }

  Future<cam.CameraController> _open({required bool audio}) async {
    final controller = cam.CameraController(_cameras[_index], cam.ResolutionPreset.high, enableAudio: audio);
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
    return controller;
  }

  static Object _failure(cam.CameraException error) =>
      error.code.startsWith("CameraAccess") ? const CameraException(CameraFailure.denied) : error;

  @override
  bool get hasMicrophone => _microphone;

  @override
  double get aspectRatio => 1 / _camera.value.aspectRatio;

  @override
  Widget preview() => cam.CameraPreview(_camera);

  @override
  Future<void> switchCamera() async {
    _index = (_index + 1) % _cameras.length;
    await _camera.setDescription(_cameras[_index]);
  }

  @override
  Future<void> setFlash(bool on) => _camera.setFlashMode(on ? cam.FlashMode.always : cam.FlashMode.off);

  // the camera plugin can't tell, but phones only have a flash on the back
  @override
  bool get hasFlash => _cameras[_index].lensDirection == cam.CameraLensDirection.back;

  @override
  Future<PickedItem> takePhoto() async {
    final file = await _camera.takePicture();
    final buffer = await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes());
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
    if (controller != null) _closing = controller.dispose();
    await _closing;
  }
}
