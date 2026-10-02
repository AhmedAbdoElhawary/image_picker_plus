import 'dart:math';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
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
    if (cached != null) return _save(cached);
    final rect = state.cropRect;
    late double scale;
    late double cropWidth;
    late double cropHeight;
    // ImageDescriptor.width throws on web, this gives the real size on every platform
    final codec = await ui.instantiateImageCodecWithSize(
      await ui.ImmutableBuffer.fromUint8List(await source.readAsBytes()),
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
    final jpeg = await encodeJpeg(pixels, width, height, output.quality);

    if (cacheKey != null) await cache?.write(cacheKey, jpeg);
    return _save(jpeg, width: width, height: height);
  }

  Future<PickedItem> _save(Uint8List jpeg, {int? width, int? height}) async {
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
