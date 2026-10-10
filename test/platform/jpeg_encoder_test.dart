import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/platform/jpeg_encoder.dart';
import 'package:image_picker_plus/src/platform/platform.dart';

void main() {
  /// red left half, blue right half, a gray band at the bottom when there is room, all opaque.
  ByteData halves(int width, int height) {
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        final gray = height > 4 && y >= height * 3 ~/ 4;
        rgba
          ..[i] = gray ? 128 : (x < (width + 1) ~/ 2 ? 255 : 0)
          ..[i + 1] = gray ? 128 : 0
          ..[i + 2] = gray ? 128 : (x < (width + 1) ~/ 2 ? 0 : 255)
          ..[i + 3] = 255;
      }
    }
    return ByteData.sublistView(rgba);
  }

  /// strips cut from the whole buffer, like the export draws them.
  Future<Uint8List> encode(ByteData rgba, int width, int height, int quality) => encodeJpeg(
    (top, rows) async => ByteData.sublistView(rgba, top * width * 4, (top + rows) * width * 4),
    width,
    height,
    quality,
  );

  void expectColor(img.Pixel pixel, int r, int g, int b) {
    expect(pixel.r, closeTo(r, 16));
    expect(pixel.g, closeTo(g, 16));
    expect(pixel.b, closeTo(b, 16));
  }

  for (final (width, height) in [(1, 1), (17, 9), (200, 100), (333, 517), (4096, 600)]) {
    test("a ${width}x$height image decodes back to its colors", () async {
      final out = img.decodeJpg(await encode(halves(width, height), width, height, 90))!;
      expect((out.width, out.height), (width, height));
      expectColor(out.getPixel(0, 0), 255, 0, 0);
      if (width > 4) expectColor(out.getPixel(width - 1, 0), 0, 0, 255);
      if (height > 4) expectColor(out.getPixel(width ~/ 4, height - 1), 128, 128, 128);
    });
  }

  test("transparent pixels come out white", () async {
    final rgba = Uint8List(32 * 32 * 4);
    final out = img.decodeJpg(await encode(ByteData.sublistView(rgba), 32, 32, 90))!;
    expectColor(out.getPixel(16, 16), 255, 255, 255);
  });

  test("a lower quality is smaller", () async {
    final pixels = halves(300, 300);
    final high = await encode(pixels, 300, 300, 95);
    final low = await encode(pixels, 300, 300, 30);
    expect(low.length, lessThan(high.length));
  });

  test("strips are about 2 mb, whole mcu rows and fit a restart interval", () {
    expect(jpegStripRows(4096), 128);
    expect(jpegStripRows(1000), 512);
    // 65535 wide is 4096 mcus a row, so 1 mcu row a strip at most
    expect(jpegStripRows(65535), 16);
  });
}
