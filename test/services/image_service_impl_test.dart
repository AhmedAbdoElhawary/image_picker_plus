import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
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
      final item = await service.export(
        grid(5000, 10),
        const EditState(),
        filters.first,
        const OutputOptions(),
      );
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
      final low = await service.export(
        grid(200, 100),
        const EditState(),
        filters[3],
        const OutputOptions(quality: 10),
      );
      final bytes = await high.file.readAsBytes();
      expect(bytes.sublist(0, 2), [0xFF, 0xD8]);
      expect(String.fromCharCodes(bytes).contains("Exif"), isFalse);
      expect(await low.file.length(), lessThan(bytes.length));
      expect(high.file.path, startsWith(dir.path));
    });
  });

  testWidgets("a jpeg is turned by its exif and the output keeps no exif", (tester) async {
    await tester.runAsync(() async {
      final image = img.Image(width: 200, height: 100)
        ..exif.imageIfd.orientation = 6
        ..exif.gpsIfd["GPSLatitude"] = 30.0;
      final file = File("${dir.path}/turned.jpg")..writeAsBytesSync(img.encodeJpg(image));
      final item = await service.export(
        XFile(file.path),
        const EditState(filterIndex: 1),
        filters[1],
        const OutputOptions(),
      );
      expect((item.width, item.height), (100, 200));
      final out = img.decodeJpg(await item.file.readAsBytes())!;
      expect(out.exif.isEmpty, isTrue);
    });
  });

  testWidgets("the same edit comes from the cache", (tester) async {
    await tester.runAsync(() async {
      final cache = FakeCacheService();
      final cached = ImageServiceImpl(root: dir.path, cache: cache);
      const state = EditState(filterIndex: 1);
      final first = await cached.export(
        grid(200, 100),
        state,
        filters[1],
        const OutputOptions(),
        cacheKey: "k",
      );
      final second = await cached.export(
        grid(200, 100),
        state,
        filters[1],
        const OutputOptions(),
        cacheKey: "k",
      );
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

  group("max bytes", () {
    /// random pixels, so a lower quality can't shrink it much and the size steps are needed.
    XFile noise(int width, int height) {
      final random = Random(1);
      final image = img.Image(width: width, height: height);
      for (final pixel in image) {
        pixel
          ..r = random.nextInt(256)
          ..g = random.nextInt(256)
          ..b = random.nextInt(256);
      }
      final file = File("${dir.path}/noise.png")..writeAsBytesSync(img.encodePng(image));
      return XFile(file.path);
    }

    Future<int> sizeAt(XFile source, int quality) async {
      final item = await service.export(
        source,
        const EditState(),
        filters.first,
        OutputOptions(quality: quality),
      );
      return item.file.length();
    }

    testWidgets("a limit above the size changes nothing", (tester) async {
      await tester.runAsync(() async {
        final source = noise(400, 300);
        final item = await service.export(
          source,
          const EditState(),
          filters.first,
          const OutputOptions(maxBytes: 100 * 1024 * 1024),
        );
        expect((item.width, item.overLimit), (400, false));
        expect(await item.file.length(), await sizeAt(source, 90));
      });
    });

    testWidgets("a lower quality is tried before a smaller size", (tester) async {
      await tester.runAsync(() async {
        final source = noise(400, 300);
        final limit = (await sizeAt(source, 90) + await sizeAt(source, OutputOptions.qualityFloor)) ~/ 2;
        final item = await service.export(
          source,
          const EditState(),
          filters.first,
          OutputOptions(maxBytes: limit),
        );
        expect(item.width, 400);
        expect(await item.file.length(), lessThanOrEqualTo(limit));
        expect(item.overLimit, isFalse);
      });
    });

    testWidgets("scales down when the lowest quality is still over", (tester) async {
      await tester.runAsync(() async {
        final source = noise(400, 300);
        final limit = await sizeAt(source, OutputOptions.qualityFloor) ~/ 3;
        final item = await service.export(
          source,
          const EditState(),
          filters.first,
          OutputOptions(maxBytes: limit),
        );
        expect(item.width, lessThan(400));
        expect(item.width / item.height, closeTo(4 / 3, 0.05));
        expect(await item.file.length(), lessThanOrEqualTo(limit));
        expect(item.overLimit, isFalse);
      });
    });

    testWidgets("a limit nothing can meet gives the smallest attempt, flagged", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          noise(400, 300),
          const EditState(),
          filters.first,
          const OutputOptions(maxBytes: 100),
        );
        expect(item.overLimit, isTrue);
        expect(item.width, lessThan(400));
      });
    });
  });
}
