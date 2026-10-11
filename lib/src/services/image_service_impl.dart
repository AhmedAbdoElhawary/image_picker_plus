import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/services/cache_service.dart';
import 'package:image_picker_plus/src/services/image_service.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class ImageServiceImpl implements ImageService {
  /// the dir path edited images are saved in, the temp dir when null. not used on web.
  final String? root;

  /// null when caching is off.
  final CacheService? cache;

  ImageServiceImpl({this.root, this.cache});

  /// the decode is capped too, a small crop of a 50 mp photo would decode it all.
  static const int maxDecodeSide = 8192;

  /// one edit at a time, a few big renders at once run out of memory and hang the gpu on android.
  Future<void> _queue = Future.value();

  @override
  Future<PickedItem> export(
    XFile source,
    EditState state,
    List<double> colorMatrix,
    OutputOptions output, {
    String? cacheKey,
  }) async {
    // the key would have to hold every stroke point, for a hit that almost never comes
    if (state.markup.isNotEmpty) cacheKey = null;
    final cached = cacheKey == null ? null : await cache?.read(cacheKey);
    if (cached != null) return _save(cached, output);
    final edit = _queue.then((_) => _edit(source, state, colorMatrix, output));
    _queue = edit.then((_) {}, onError: (_) {});
    final (bytes, width, height) = await edit;
    // the picker doesn't wait for the disk, a lost write only means no cache
    if (cacheKey != null) unawaited(cache?.write(cacheKey, bytes));
    return _save(bytes, output, width: width, height: height);
  }

  /// the engine decodes natively and only at the needed size, way faster than the image package,
  /// and it reads heic too. only the jpeg encode is left for an isolate.
  Future<(Uint8List, int, int)> _edit(
    XFile source,
    EditState state,
    List<double> colorMatrix,
    OutputOptions output,
  ) async {
    final rect = state.cropRect;
    late double scale;
    late double cropWidth;
    late double cropHeight;
    // ImageDescriptor.width throws on web, this gives the real size on every platform
    final codec = await ui.instantiateImageCodecWithSize(
      await imageBuffer(source),
      getTargetSize: (width, height) {
        // the crop is of the image as shown, which a quarter turn swaps
        final turned = state.turns.isOdd;
        cropWidth = rect.width * (turned ? height : width);
        cropHeight = rect.height * (turned ? width : height);
        scale = outputScale(cropWidth, cropHeight, output);
        final decodeScale = min(scale, maxDecodeSide / max(width, height));
        return ui.TargetImageSize(
          width: max(1, (width * decodeScale).round()),
          height: max(1, (height * decodeScale).round()),
        );
      },
    );
    final decoded = (await codec.getNextFrame()).image;
    codec.dispose();

    var width = max(1, (cropWidth * scale).round());
    var height = max(1, (cropHeight * scale).round());
    final png = output.format == OutputFormat.png;
    // raw pixels carry no exif, so the output has no location or camera data
    Future<Uint8List> encode(int width, int height, int quality) async {
      if (!png) {
        return encodeJpeg(
          (top, rows) => _draw(decoded, state, colorMatrix, width, height, top, rows),
          width,
          height,
          quality,
        );
      }
      final image = await _render(decoded, state, colorMatrix, width, height, 0, height, png: true);
      try {
        return await encodePng(image);
      } finally {
        image.dispose();
      }
    }

    // 4 bands spread down the image, an eighth of it in all, tell its size at a quality
    Future<bool> clearlyOver(int quality, int limit) async {
      final rows = max(16, (height ~/ 32 + 15) & ~15);
      if (rows * 4 >= height) return false;
      Future<Uint8List> band(int top) => encodeJpeg(
        (offset, count) => _draw(decoded, state, colorMatrix, width, height, top + offset, count),
        width,
        rows,
        quality,
      );
      // on the mcu grid of the whole, so a band encodes like that part of it
      final bands = await Future.wait([
        for (var i = 0; i < 4; i++) band(((height - rows) * (2 * i + 1) ~/ 8) & ~15),
      ]);
      final bytes = bands.fold(0, (sum, jpeg) => sum + jpeg.length);
      // each band has its own headers so it reads a bit high, only a clear miss counts
      return bytes * height / (rows * 4) > limit * 1.1;
    }

    final maxBytes = output.maxBytes;
    // a lower quality first, it keeps more detail than a smaller size
    // png has no quality, only a smaller size makes it smaller
    final qualities = [
      output.quality,
      if (!png)
        for (final quality in [80, 65, OutputOptions.qualityFloor])
          if (quality < output.quality) quality,
    ];
    var step = 0;
    // the whole image is only encoded at a quality that may fit, a full encode is the slow part
    while (maxBytes != null && step < qualities.length - 1 && await clearlyOver(qualities[step], maxBytes)) {
      step++;
    }
    var best = (await encode(width, height, qualities[step]), width, height);
    if (maxBytes != null) {
      while (best.$1.length > maxBytes && ++step < qualities.length) {
        final encoded = await encode(width, height, qualities[step]);
        if (encoded.length < best.$1.length) best = (encoded, width, height);
      }
      final quality = min(output.quality, OutputOptions.qualityFloor);
      for (var i = 0; i < 3 && best.$1.length > maxBytes; i++) {
        final shrink = sqrt(maxBytes / best.$1.length) * 0.9;
        width = max(1, (best.$2 * shrink).round());
        height = max(1, (best.$3 * shrink).round());
        final encoded = await encode(width, height, quality);
        if (encoded.length < best.$1.length) best = (encoded, width, height);
      }
    }
    decoded.dispose();
    return best;
  }

  /// [rows] of the output from [top], a strip keeps the gpu target and the pixels small.
  Future<ByteData> _draw(
    ui.Image decoded,
    EditState state,
    List<double> colorMatrix,
    int width,
    int height,
    int top,
    int rows,
  ) async {
    final drawn = await _render(decoded, state, colorMatrix, width, height, top, rows, png: false);
    final pixels = await drawn.toByteData(format: ui.ImageByteFormat.rawRgba);
    drawn.dispose();
    if (pixels == null) throw StateError("couldn't read the edited pixels");
    return pixels;
  }

  /// the whole image as shown is drawn turned and flipped, then the crop of it fills the output.
  /// the markup goes on the same canvas after the filtered image, so the filter never touches it.
  /// a jpeg has no transparency, so it gets a white background first.
  Future<ui.Image> _render(
    ui.Image decoded,
    EditState state,
    List<double> colorMatrix,
    int width,
    int height,
    int top,
    int rows, {
    required bool png,
  }) async {
    final rect = state.cropRect;
    // the whole image as shown at the output scale
    final whole = Size(width / rect.width, height / rect.height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (!png) canvas.drawColor(OutputOptions.jpegBackground, BlendMode.src);
    canvas
      ..translate(0, -top.toDouble())
      ..clipRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()))
      ..translate(-rect.left * whole.width, -rect.top * whole.height)
      ..save()
      ..translate(whole.width / 2, whole.height / 2)
      ..rotate(-state.turns * pi / 2);
    if (state.flipped) canvas.scale(-1, 1);
    final turned = state.turns.isOdd;
    canvas
      ..drawImageRect(
        decoded,
        Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
        Rect.fromCenter(
          center: Offset.zero,
          width: turned ? whole.height : whole.width,
          height: turned ? whole.width : whole.height,
        ),
        Paint()
          ..colorFilter = ColorFilter.matrix(colorMatrix)
          ..filterQuality = FilterQuality.high,
      )
      ..restore();
    if (state.markup.isNotEmpty) MarkupPainter(items: state.markup).paint(canvas, whole);
    final picture = recorder.endRecording();
    final drawn = await picture.toImage(width, rows);
    picture.dispose();
    return drawn;
  }

  Future<PickedItem> _save(Uint8List bytes, OutputOptions output, {int? width, int? height}) async {
    if (width == null || height == null) {
      // only a cache hit gets here, mobile only, where the descriptor reads the size from the header
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      width = descriptor.width;
      height = descriptor.height;
      descriptor.dispose();
      buffer.dispose();
    }
    return PickedItem(
      file: await saveImage(bytes, output.format, root: root),
      type: MediaType.image,
      width: width,
      height: height,
      edited: true,
      overLimit: output.maxBytes != null && bytes.length > output.maxBytes!,
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
