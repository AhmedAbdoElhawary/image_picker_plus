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

Future<Uint8List> encodeJpeg(ByteData rgba, int width, int height, int quality) => Isolate.run(
  () => img.encodeJpg(
    img.Image.fromBytes(width: width, height: height, bytes: rgba.buffer, numChannels: 4),
    quality: quality,
  ),
);

/// all of it in an isolate, a big photo decoded and drawn on the main side drops frames.
/// null when the image package can't read the file, like a heic picked on android.
Future<(Uint8List, int, int)?> editJpeg(XFile source, Rect crop, List<double> matrix, OutputOptions output) {
  final path = source.path;
  return Isolate.run(() {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return null;
    // the crop rect is on the image as shown, so turned by its exif
    final image = img.bakeOrientation(decoded);
    final cropWidth = crop.width * image.width;
    final cropHeight = crop.height * image.height;
    final scale = ImageServiceImpl.outputScale(cropWidth, cropHeight, output);
    final width = max(1, (cropWidth * scale).round());
    final height = max(1, (cropHeight * scale).round());
    var edited = img.copyCrop(
      image,
      x: (crop.left * image.width).round(),
      y: (crop.top * image.height).round(),
      width: max(1, cropWidth.round()),
      height: max(1, cropHeight.round()),
    );
    if (edited.width != width || edited.height != height) {
      edited = img.copyResize(edited, width: width, height: height, interpolation: img.Interpolation.average);
    }
    // the matrix works on 8 bit rgb, png can be 16 bit, gray or a palette
    if (edited.format != img.Format.uint8 || edited.hasPalette || edited.numChannels < 3) {
      edited = edited.convert(format: img.Format.uint8, numChannels: max(3, edited.numChannels));
    }
    _applyMatrix(edited, matrix);
    // no exif, so no location or camera data
    edited.exif = img.ExifData();
    return (img.encodeJpg(edited, quality: output.quality), width, height);
  });
}

/// the same 5x4 matrix as [ColorFilter.matrix], offsets in 0..255.
void _applyMatrix(img.Image image, List<double> m) {
  const identity = [1.0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  if (listEquals(m, identity)) return;
  final bytes = image.toUint8List();
  final channels = image.numChannels;
  for (var i = 0; i < bytes.length; i += channels) {
    final r = bytes[i];
    final g = bytes[i + 1];
    final b = bytes[i + 2];
    final a = channels == 4 ? bytes[i + 3] : 255;
    bytes[i] = _byte(m[0] * r + m[1] * g + m[2] * b + m[3] * a + m[4]);
    bytes[i + 1] = _byte(m[5] * r + m[6] * g + m[7] * b + m[8] * a + m[9]);
    bytes[i + 2] = _byte(m[10] * r + m[11] * g + m[12] * b + m[13] * a + m[14]);
    if (channels == 4) bytes[i + 3] = _byte(m[15] * r + m[16] * g + m[17] * b + m[18] * a + m[19]);
  }
}

int _byte(double value) => value <= 0 ? 0 : (value >= 255 ? 255 : value.round());

Future<XFile> saveJpeg(Uint8List jpeg, {String? root}) async {
  final dir = Directory(root ?? "${Directory.systemTemp.path}/image_picker_plus");
  await dir.create(recursive: true);
  final name = "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}.jpg";
  final file = await File("${dir.path}/$name").writeAsBytes(jpeg, flush: true);
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
