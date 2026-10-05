import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/platform/video_handle.dart';
import 'package:image_picker_plus/src/services/cache_service_impl.dart';
import 'package:image_picker_plus/src/services/camera_service_impl.dart';
import 'package:image_picker_plus/src/services/files_service_impl.dart';
import 'package:image_picker_plus/src/services/gallery_service_impl.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:video_player/video_player.dart';

final Random _random = Random();

PickerServices platformServices(PickerSettings settings) {
  final mobile =
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  final cache = mobile && settings.cache.enabled ? CacheServiceImpl(maxBytes: settings.cache.maxBytes) : null;
  return PickerServices(
    gallery: mobile ? GalleryServiceImpl() : null,
    camera: CameraServiceImpl.new,
    image: ImageServiceImpl(cache: cache),
    files: FilesServiceImpl(),
    cache: cache,
  );
}

Future<void> clearCache() => CacheServiceImpl(maxBytes: 1).clear();

ImageProvider fileImage(String path) => FileImage(File(path));

/// read by the engine, the file never gets copied through dart on the main thread.
Future<ui.ImmutableBuffer> imageBuffer(XFile file) => ui.ImmutableBuffer.fromFilePath(file.path);

VideoHandle? videoPlayer(String path) => _FileVideo(VideoPlayerController.file(File(path)));

/// the pixels are premultiplied, so over white it's the color plus what alpha leaves.
/// 3 channels and 4:2:0 encode about twice as fast.
Future<Uint8List> encodeJpeg(ByteData rgba, int width, int height, int quality) => Isolate.run(() {
  final pixels = rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes);
  final rgb = Uint8List(width * height * 3);
  for (var i = 0, j = 0; i < pixels.length; i += 4, j += 3) {
    final rest = 255 - pixels[i + 3];
    rgb[j] = pixels[i] + rest;
    rgb[j + 1] = pixels[i + 1] + rest;
    rgb[j + 2] = pixels[i + 2] + rest;
  }
  return img.encodeJpg(
    img.Image.fromBytes(width: width, height: height, bytes: rgb.buffer, numChannels: 3),
    quality: quality,
    chroma: img.JpegChroma.yuv420,
  );
});

Future<XFile> saveJpeg(Uint8List jpeg, {String? root}) async {
  final dir = Directory(root ?? "${Directory.systemTemp.path}/image_picker_plus");
  await dir.create(recursive: true);
  final name = "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}.jpg";
  final file = await File("${dir.path}/$name").writeAsBytes(jpeg);
  return XFile(file.path, mimeType: "image/jpeg");
}

class _FileVideo implements VideoHandle {
  final VideoPlayerController _player;

  _FileVideo(this._player);

  @override
  bool get isInitialized => _player.value.isInitialized;

  @override
  bool get isPlaying => _player.value.isPlaying;

  @override
  double get aspectRatio => _player.value.aspectRatio;

  @override
  Future<void> initialize({required bool muted}) async {
    await _player.initialize();
    await _player.setLooping(true);
    if (muted) await _player.setVolume(0);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Widget view() => VideoPlayer(_player);

  @override
  void dispose() => unawaited(_player.dispose());

  @override
  void addListener(VoidCallback listener) => _player.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _player.removeListener(listener);
}
