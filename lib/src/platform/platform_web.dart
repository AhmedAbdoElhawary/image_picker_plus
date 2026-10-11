import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/platform/video_handle.dart';
import 'package:image_picker_plus/src/services/camera_service_impl.dart';
import 'package:image_picker_plus/src/services/files_service_impl.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:web/web.dart' as web;

PickerServices platformServices(PickerSettings settings) => PickerServices(
  gallery: null,
  camera: CameraServiceImpl.new,
  image: ImageServiceImpl(),
  files: FilesServiceImpl(),
);

Future<void> clearCache() async {}

/// [path] is a blob url on web.
ImageProvider fileImage(String path) => NetworkImage(path);

Future<ui.ImmutableBuffer> imageBuffer(XFile file) async =>
    ui.ImmutableBuffer.fromUint8List(await file.readAsBytes());

/// no player here, video_player's library imports dart:io and that would keep the
/// package off wasm. the preview shows the file name instead, like windows and linux.
VideoHandle? videoPlayer(String path) => null;

/// the browser encodes off the main thread, a dart encoder would freeze the page.
/// it takes the whole image, so it's drawn in one go here.
Future<Uint8List> encodeJpeg(
  Future<ByteData> Function(int top, int rows) draw,
  int width,
  int height,
  int quality,
) async => _encode(await draw(0, height), width, height, "image/jpeg", quality: quality / 100);

Future<Uint8List> _encode(ByteData rgba, int width, int height, String type, {double? quality}) async {
  final canvas = web.OffscreenCanvas(width, height);
  final context = canvas.getContext("2d")! as web.OffscreenCanvasRenderingContext2D;
  final pixels = rgba.buffer.asUint8ClampedList(rgba.offsetInBytes, rgba.lengthInBytes);
  context.putImageData(web.ImageData(pixels.toJS, width, height.toJS), 0, 0);
  final blob = await canvas
      .convertToBlob(
        quality == null
            ? web.ImageEncodeOptions(type: type)
            : web.ImageEncodeOptions(type: type, quality: quality),
      )
      .toDart;
  final buffer = await blob.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

/// the browser encodes it off the main thread, like the jpeg.
Future<Uint8List> encodePng(ui.Image image) async {
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  if (rgba == null) throw StateError("couldn't read the edited pixels");
  return _encode(rgba, image.width, image.height, "image/png");
}

Future<XFile> saveImage(Uint8List bytes, OutputFormat format, {String? root}) async => XFile.fromData(
  bytes,
  mimeType: "image/${format.name}",
  name: "${DateTime.now().microsecondsSinceEpoch}.${format == OutputFormat.jpeg ? "jpg" : "png"}",
);
