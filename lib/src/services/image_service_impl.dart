import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
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

  @override
  Future<PickedItem> export(
    XFile source,
    EditState state,
    List<double> colorMatrix,
    OutputOptions output, {
    String? cacheKey,
  }) async {
    final cached = cacheKey == null ? null : await cache?.read(cacheKey);
    if (cached != null) return _save(cached, output);
    final (jpeg, width, height) = await _edit(source, state.cropRect, colorMatrix, output);
    final saving = _save(jpeg, output, width: width, height: height);
    if (cacheKey != null) await cache?.write(cacheKey, jpeg);
    return saving;
  }

  /// the engine decodes natively and only at the needed size, way faster than the image package,
  /// and it reads heic too. only the jpeg encode is left for an isolate.
  Future<(Uint8List, int, int)> _edit(
    XFile source,
    Rect rect,
    List<double> colorMatrix,
    OutputOptions output,
  ) async {
    late double scale;
    late double cropWidth;
    late double cropHeight;
    // ImageDescriptor.width throws on web, this gives the real size on every platform
    final codec = await ui.instantiateImageCodecWithSize(
      await imageBuffer(source),
      getTargetSize: (width, height) {
        cropWidth = rect.width * width;
        cropHeight = rect.height * height;
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
    var pixels = await _draw(decoded, rect, colorMatrix, width, height);
    // raw pixels carry no exif, so the output has no location or camera data
    var best = (await encodeJpeg(pixels, width, height, output.quality), width, height);
    final maxBytes = output.maxBytes;
    if (maxBytes != null) {
      // a lower quality first, it keeps more detail than a smaller size
      for (final quality in [80, 65, OutputOptions.qualityFloor]) {
        if (best.$1.length <= maxBytes) break;
        if (quality >= output.quality) continue;
        final jpeg = await encodeJpeg(pixels, width, height, quality);
        if (jpeg.length < best.$1.length) best = (jpeg, width, height);
      }
      final quality = min(output.quality, OutputOptions.qualityFloor);
      for (var i = 0; i < 3 && best.$1.length > maxBytes; i++) {
        final shrink = sqrt(maxBytes / best.$1.length) * 0.9;
        width = max(1, (best.$2 * shrink).round());
        height = max(1, (best.$3 * shrink).round());
        pixels = await _draw(decoded, rect, colorMatrix, width, height);
        final jpeg = await encodeJpeg(pixels, width, height, quality);
        if (jpeg.length < best.$1.length) best = (jpeg, width, height);
      }
    }
    decoded.dispose();
    return best;
  }

  Future<ByteData> _draw(ui.Image decoded, Rect rect, List<double> colorMatrix, int width, int height) async {
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
    final pixels = await drawn.toByteData(format: ui.ImageByteFormat.rawRgba);
    drawn.dispose();
    if (pixels == null) throw StateError("couldn't read the edited pixels");
    return pixels;
  }

  Future<PickedItem> _save(Uint8List jpeg, OutputOptions output, {int? width, int? height}) async {
    if (width == null || height == null) {
      final codec = await ui.instantiateImageCodecWithSize(await ui.ImmutableBuffer.fromUint8List(jpeg));
      final image = (await codec.getNextFrame()).image;
      width = image.width;
      height = image.height;
      image.dispose();
      codec.dispose();
    }
    return PickedItem(
      file: await saveJpeg(jpeg, root: root),
      type: MediaType.image,
      width: width,
      height: height,
      edited: true,
      overLimit: output.maxBytes != null && jpeg.length > output.maxBytes!,
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
