import 'dart:io';
import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/services/image_service.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';

import '../fakes/fake_cache_service.dart';

void main() {
  late Directory dir;
  late ImageServiceImpl service;

  setUp(() {
    dir = Directory.systemTemp.createTempSync("image_service_test");
    service = ImageServiceImpl(root: dir.path);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// red top left, green top right, blue bottom left, white bottom right.
  XFile grid(int width, int height) {
    final image = img.Image(width: width, height: height);
    for (final pixel in image) {
      final right = pixel.x >= width / 2;
      final bottom = pixel.y >= height / 2;
      pixel
        ..r = !bottom && !right || bottom && right ? 255 : 0
        ..g = !bottom && right || bottom && right ? 255 : 0
        ..b = bottom ? 255 : 0;
    }
    final file = File("${dir.path}/source_${width}x$height.png")..writeAsBytesSync(img.encodePng(image));
    return XFile(file.path);
  }

  Future<img.Image> decode(XFile file) async => img.decodeJpg(await file.readAsBytes())!;

  void expectColor(img.Pixel pixel, int r, int g, int b) {
    expect(pixel.r, closeTo(r, 24));
    expect(pixel.g, closeTo(g, 24));
    expect(pixel.b, closeTo(b, 24));
  }

  testWidgets("the crop rect gives the right size and colors", (tester) async {
    await tester.runAsync(() async {
      const state = EditState(cropRect: Rect.fromLTWH(0.5, 0, 0.5, 1));
      final item = await service.export(grid(200, 100), state, filters.first, const OutputOptions());
      expect(item.edited, isTrue);
      expect((item.width, item.height), (100, 100));
      final out = await decode(item.file);
      expectColor(out.getPixel(10, 10), 0, 255, 0);
      expectColor(out.getPixel(90, 90), 255, 255, 255);
    });
  });

  testWidgets("a filter changes the pixels", (tester) async {
    await tester.runAsync(() async {
      const state = EditState(cropRect: Rect.fromLTWH(0, 0, 0.5, 0.5), filterIndex: 12);
      final item = await service.export(grid(200, 100), state, filters[12], const OutputOptions());
      final pixel = (await decode(item.file)).getPixel(20, 20);
      // mono, so red turns gray
      expect(pixel.r, closeTo(pixel.g, 24));
      expect(pixel.g, closeTo(pixel.b, 24));
    });
  });

  testWidgets("max width and height scale down keeping the ratio", (tester) async {
    await tester.runAsync(() async {
      final wide = await service.export(
        grid(200, 100),
        const EditState(),
        filters.first,
        const OutputOptions(maxWidth: 50),
      );
      expect((wide.width, wide.height), (50, 25));
      final tall = await service.export(
        grid(200, 100),
        const EditState(),
        filters.first,
        const OutputOptions(maxHeight: 20),
      );
      expect((tall.width, tall.height), (40, 20));
      final small = await service.export(
        grid(200, 100),
        const EditState(),
        filters.first,
        const OutputOptions(maxWidth: 999),
      );
      expect((small.width, small.height), (200, 100));
    });
  });

  testWidgets("with no max the long side is capped", (tester) async {
    await tester.runAsync(() async {
      final item = await service.export(grid(5000, 10), const EditState(), filters.first, const OutputOptions());
      expect(item.width, OutputOptions.safeMaxSide);
    });
  });

  testWidgets("the output is a jpeg with no exif and the quality changes the size", (tester) async {
    await tester.runAsync(() async {
      final high = await service.export(
        grid(200, 100),
        const EditState(),
        filters[3],
        const OutputOptions(quality: 100),
      );
      final low = await service.export(grid(200, 100), const EditState(), filters[3], const OutputOptions(quality: 10));
      final bytes = await high.file.readAsBytes();
      expect(bytes.sublist(0, 2), [0xFF, 0xD8]);
      expect(String.fromCharCodes(bytes).contains("Exif"), isFalse);
      expect(await low.file.length(), lessThan(bytes.length));
      expect(high.file.path, startsWith(dir.path));
    });
  });

  testWidgets("the same edit comes from the cache", (tester) async {
    await tester.runAsync(() async {
      final cache = FakeCacheService();
      final cached = ImageServiceImpl(root: dir.path, cache: cache);
      const state = EditState(filterIndex: 1);
      final first = await cached.export(grid(200, 100), state, filters[1], const OutputOptions(), cacheKey: "k");
      final second = await cached.export(grid(200, 100), state, filters[1], const OutputOptions(), cacheKey: "k");
      expect(cache.writes, 1);
      expect((second.width, second.height), (first.width, first.height));
      expect(await second.file.readAsBytes(), await first.file.readAsBytes());
    });
  });

  test("output scale", () {
    expect(ImageServiceImpl.outputScale(100, 100, const OutputOptions()), 1);
    expect(ImageServiceImpl.outputScale(8192, 100, const OutputOptions()), 0.5);
    expect(ImageServiceImpl.outputScale(200, 100, const OutputOptions(maxWidth: 100, maxHeight: 10)), 0.1);
  });
}
