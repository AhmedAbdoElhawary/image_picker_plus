import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
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

/// the engine decodes natively and only at the size [targetSize] asks for. the descriptor is
/// disposed here, instantiateImageCodecWithSize leaves it holding the encoded photo until a gc.
Future<ui.Image> decodeImage(XFile file, ui.TargetImageSizeCallback targetSize) async {
  final buffer = await imageBuffer(file);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  try {
    final size = targetSize(descriptor.width, descriptor.height);
    final codec = await descriptor.instantiateCodec(targetWidth: size.width, targetHeight: size.height);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor.dispose();
    buffer.dispose();
  }
}

VideoHandle? videoPlayer(String path) => _FileVideo(VideoPlayerController.file(File(path)));

/// a strip is drawn, encoded and appended, one at a time. the encode runs here and not in an
/// isolate on purpose: sending a strip over copies its pixels, and a few strips in flight were
/// 30 mb of them for a 12 mp photo. this is slower and the export is what the memory is for.
Future<Uint8List> encodeJpeg(
  Future<ByteData> Function(int top, int rows) draw,
  int width,
  int height,
  int quality,
) async {
  final rows = jpegStripRows(width);
  final count = (height + rows - 1) ~/ rows;
  final encoder = JpegStripEncoder(width, quality);
  // every strip is copied in as it comes, so the encoder's buffer can take the next one
  final jpeg = BytesBuilder()..add(jpegHeader(width, height, quality, count > 1 ? rows : null));
  for (var index = 0; index < count; index++) {
    final top = index * rows;
    final strip = min(rows, height - top);
    if (index > 0) jpeg.add(restartMarker(index - 1));
    final pixels = await draw(top, strip);
    jpeg.add(encoder.encode(pixels.buffer.asUint8List(pixels.offsetInBytes, pixels.lengthInBytes), strip));
  }
  jpeg.add(jpegEnd);
  return jpeg.takeBytes();
}

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
