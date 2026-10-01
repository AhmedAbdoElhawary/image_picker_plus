import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/cache_service.dart';
import 'package:image_picker_plus/src/services/image_service.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class ImageServiceImpl implements ImageService {
  final Directory? root;

  /// null when caching is off.
  final CacheService? cache;

  ImageServiceImpl({this.root, this.cache});

  /// the decode is capped too, a small crop of a 50 mp photo would decode it all.
  static const int maxDecodeSide = 8192;

  static final Random _random = Random();

  @override
  Future<PickedItem> export(
    XFile source,
    EditState state,
    List<double> colorMatrix,
    OutputOptions output, {
    String? cacheKey,
  }) async {
    final cached = cacheKey == null ? null : await cache?.read(cacheKey);
    if (cached != null) return _save(cached);
    final buffer = await ui.ImmutableBuffer.fromUint8List(await source.readAsBytes());
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final rect = state.cropRect;
    final cropWidth = rect.width * descriptor.width;
    final cropHeight = rect.height * descriptor.height;
    final scale = outputScale(cropWidth, cropHeight, output);
    final decodeScale = min(scale, maxDecodeSide / max(descriptor.width, descriptor.height));

    final codec = await descriptor.instantiateCodec(
      targetWidth: max(1, (descriptor.width * decodeScale).round()),
      targetHeight: max(1, (descriptor.height * decodeScale).round()),
    );
    final decoded = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();

    final width = max(1, (cropWidth * scale).round());
    final height = max(1, (cropHeight * scale).round());
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      decoded,
      Rect.fromLTRB(
        rect.left * decoded.width,
        rect.top * decoded.height,
        rect.right * decoded.width,
        rect.bottom * decoded.height,
      ),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()
        ..colorFilter = ColorFilter.matrix(colorMatrix)
        ..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final drawn = await picture.toImage(width, height);
    picture.dispose();
    decoded.dispose();
    final pixels = await drawn.toByteData(format: ui.ImageByteFormat.rawRgba);
    drawn.dispose();
    if (pixels == null) throw StateError("couldn't read the edited pixels");

    // raw pixels carry no exif, so the output has no location or camera data
    final quality = output.quality;
    final jpeg = await Isolate.run(
      () => img.encodeJpg(
        img.Image.fromBytes(width: width, height: height, bytes: pixels.buffer, numChannels: 4),
        quality: quality,
      ),
    );

    if (cacheKey != null) await cache?.write(cacheKey, jpeg);
    return _save(jpeg, width: width, height: height);
  }

  Future<PickedItem> _save(Uint8List jpeg, {int? width, int? height}) async {
    if (width == null || height == null) {
      final descriptor = await ui.ImageDescriptor.encoded(await ui.ImmutableBuffer.fromUint8List(jpeg));
      width = descriptor.width;
      height = descriptor.height;
      descriptor.dispose();
    }
    final dir = root ?? Directory("${Directory.systemTemp.path}/image_picker_plus");
    await dir.create(recursive: true);
    final name = "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}.jpg";
    final file = await File("${dir.path}/$name").writeAsBytes(jpeg, flush: true);
    return PickedItem(
      file: XFile(file.path, mimeType: "image/jpeg"),
      type: MediaType.image,
      width: width,
      height: height,
      edited: true,
    );
  }

  /// scale of the crop so it fits the max sizes, never above 1.
  static double outputScale(double cropWidth, double cropHeight, OutputOptions output) {
    var scale = 1.0;
    final maxWidth = output.maxWidth;
    final maxHeight = output.maxHeight;
    if (maxWidth == null && maxHeight == null) {
      scale = min(scale, OutputOptions.safeMaxSide / max(cropWidth, cropHeight));
    }
    if (maxWidth != null) scale = min(scale, maxWidth / cropWidth);
    if (maxHeight != null) scale = min(scale, maxHeight / cropHeight);
    return scale;
  }
}
