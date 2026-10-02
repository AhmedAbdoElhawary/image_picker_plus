import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/services/cache_service_impl.dart';
import 'package:image_picker_plus/src/services/camera_service_impl.dart';
import 'package:image_picker_plus/src/services/files_service_impl.dart';
import 'package:image_picker_plus/src/services/gallery_service_impl.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:video_player/video_player.dart';

final Random _random = Random();

PickerServices platformServices(PickerSettings settings) {
  final mobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
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

VideoPlayerController videoPlayer(String path) => VideoPlayerController.file(File(path));

Future<Uint8List> encodeJpeg(ByteData rgba, int width, int height, int quality) => Isolate.run(
  () => img.encodeJpg(
    img.Image.fromBytes(width: width, height: height, bytes: rgba.buffer, numChannels: 4),
    quality: quality,
  ),
);

Future<XFile> saveJpeg(Uint8List jpeg, {String? root}) async {
  final dir = Directory(root ?? "${Directory.systemTemp.path}/image_picker_plus");
  await dir.create(recursive: true);
  final name = "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}.jpg";
  final file = await File("${dir.path}/$name").writeAsBytes(jpeg, flush: true);
  return XFile(file.path, mimeType: "image/jpeg");
}
