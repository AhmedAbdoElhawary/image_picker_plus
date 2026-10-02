import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/services/camera_service_impl.dart';
import 'package:image_picker_plus/src/services/files_service_impl.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

PickerServices platformServices(PickerSettings settings) =>
    PickerServices(gallery: null, camera: CameraServiceImpl.new, image: ImageServiceImpl(), files: FilesServiceImpl());

Future<void> clearCache() async {}

/// [path] is a blob url on web.
ImageProvider fileImage(String path) => NetworkImage(path);

Future<ui.ImmutableBuffer> imageBuffer(XFile file) async => ui.ImmutableBuffer.fromUint8List(await file.readAsBytes());

VideoPlayerController videoPlayer(String path) => VideoPlayerController.networkUrl(Uri.parse(path));

/// the browser encodes off the main thread, the image package would freeze the page.
Future<Uint8List> encodeJpeg(ByteData rgba, int width, int height, int quality) async {
  final canvas = web.OffscreenCanvas(width, height);
  final context = canvas.getContext("2d")! as web.OffscreenCanvasRenderingContext2D;
  final pixels = rgba.buffer.asUint8ClampedList(rgba.offsetInBytes, rgba.lengthInBytes);
  context.putImageData(web.ImageData(pixels.toJS, width, height.toJS), 0, 0);
  final blob = await canvas.convertToBlob(web.ImageEncodeOptions(type: "image/jpeg", quality: quality / 100)).toDart;
  final buffer = await blob.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

/// web has no isolates, compute would run it on the page thread too, so the engine draws it.
Future<(Uint8List, int, int)?> editJpeg(XFile source, Rect crop, List<double> matrix, OutputOptions output) async =>
    null;

Future<XFile> saveJpeg(Uint8List jpeg, {String? root}) async =>
    XFile.fromData(jpeg, mimeType: "image/jpeg", name: "${DateTime.now().microsecondsSinceEpoch}.jpg");
