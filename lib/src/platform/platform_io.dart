import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/platform/jpeg_encoder.dart';
import 'package:image_picker_plus/src/platform/video_handle.dart';
import 'package:image_picker_plus/src/services/cache_service_impl.dart';
import 'package:image_picker_plus/src/services/camera_service_impl.dart';
import 'package:image_picker_plus/src/services/files_service_impl.dart';
import 'package:image_picker_plus/src/services/gallery_service_impl.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
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

/// one core stays for the gpu draws, a few strips encode at once on the rest.
final int _workers = max(1, min(4, Platform.numberOfProcessors - 1));

/// a few strips drawn and encoded at once, so the encode uses that many cores
/// and only a few mb of pixels are ever out of the gpu.
Future<Uint8List> encodeJpeg(
  Future<ByteData> Function(int top, int rows) draw,
  int width,
  int height,
  int quality,
) async {
  final rows = jpegStripRows(width);
  final strips = List.filled((height + rows - 1) ~/ rows, Uint8List(0));
  var next = 0;
  Future<void> worker() async {
    while (next < strips.length) {
      final index = next++;
      final top = index * rows;
      final strip = min(rows, height - top);
      strips[index] = await _encodeStrip(await draw(top, strip), width, strip, quality);
    }
  }

  await Future.wait([for (var i = 0; i < _workers; i++) worker()]);
  return joinJpeg(strips, width, height, quality, rows);
}

/// its own function, a closure in encodeJpeg would carry draw and its image to the isolate.
Future<Uint8List> _encodeStrip(ByteData pixels, int width, int height, int quality) => Isolate.run(
  () => encodeJpegStrip(
    pixels.buffer.asUint8List(pixels.offsetInBytes, pixels.lengthInBytes),
    width,
    height,
    quality,
  ),
);

/// the engine encodes it off the dart thread.
Future<Uint8List> encodePng(ui.Image image) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) throw StateError("couldn't encode the png");
  return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
}

Future<XFile> saveImage(Uint8List bytes, OutputFormat format, {String? root}) async {
  final dir = Directory(root ?? "${Directory.systemTemp.path}/image_picker_plus");
  await dir.create(recursive: true);
  final name = "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}.${_extension(format)}";
  final file = await File("${dir.path}/$name").writeAsBytes(bytes);
  return XFile(file.path, mimeType: "image/${format.name}");
}

String _extension(OutputFormat format) => format == OutputFormat.jpeg ? "jpg" : "png";

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
