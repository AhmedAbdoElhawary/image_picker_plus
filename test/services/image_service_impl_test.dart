import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';

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
      final item = await service.export(grid(200, 100), state, PickerFilter.identity, const OutputOptions());
      expect(item.edited, isTrue);
      expect((item.width, item.height), (100, 100));
      final out = await decode(item.file);
      expectColor(out.getPixel(10, 10), 0, 255, 0);
      expectColor(out.getPixel(90, 90), 255, 255, 255);
    });
  });

  testWidgets("a tall image is drawn in strips that line up", (tester) async {
    await tester.runAsync(() async {
      // 128 rows a strip at this width, so 5 strips
      final item = await service.export(
        grid(4096, 600),
        const EditState(),
        PickerFilter.identity,
        const OutputOptions(),
      );
      expect((item.width, item.height), (4096, 600));
      final out = await decode(item.file);
      expectColor(out.getPixel(10, 250), 255, 0, 0);
      expectColor(out.getPixel(10, 260), 255, 0, 0);
      expectColor(out.getPixel(4000, 290), 0, 255, 0);
      expectColor(out.getPixel(10, 310), 0, 0, 255);
      expectColor(out.getPixel(4000, 590), 255, 255, 255);
    });
  });

  testWidgets("a filter changes the pixels", (tester) async {
    await tester.runAsync(() async {
      const state = EditState(cropRect: Rect.fromLTWH(0, 0, 0.5, 0.5), filterIndex: 12);
      final item = await service.export(
        grid(200, 100),
        state,
        PickerFilter.all[11].matrix,
        const OutputOptions(),
      );
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
        PickerFilter.identity,
        const OutputOptions(maxWidth: 50),
      );
      expect((wide.width, wide.height), (50, 25));
      final tall = await service.export(
        grid(200, 100),
        const EditState(),
        PickerFilter.identity,
        const OutputOptions(maxHeight: 20),
      );
      expect((tall.width, tall.height), (40, 20));
      final small = await service.export(
        grid(200, 100),
        const EditState(),
        PickerFilter.identity,
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
        PickerFilter.identity,
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
        PickerFilter.all[2].matrix,
        const OutputOptions(quality: 100),
      );
      final low = await service.export(
        grid(200, 100),
        const EditState(),
        PickerFilter.all[2].matrix,
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
        PickerFilter.all[0].matrix,
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
        PickerFilter.all[0].matrix,
        const OutputOptions(),
        cacheKey: "k",
      );
      final second = await cached.export(
        grid(200, 100),
        state,
        PickerFilter.all[0].matrix,
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
        PickerFilter.identity,
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
          PickerFilter.identity,
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
          PickerFilter.identity,
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
          PickerFilter.identity,
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
          PickerFilter.identity,
          const OutputOptions(maxBytes: 100),
        );
        expect(item.overLimit, isTrue);
        expect(item.width, lessThan(400));
      });
    });
  });

  group("markup", () {
    const red = Color(0xFFFF0000);
    // across the middle, on the grid's four colors
    const stroke = StrokeMark(points: [Offset(0, 0.5), Offset(1, 0.5)], color: red, width: 0.1);

    testWidgets("a stroke lands where it was drawn and leaves the rest", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          grid(200, 100),
          const EditState(markup: [stroke]),
          PickerFilter.identity,
          const OutputOptions(),
        );
        final out = await decode(item.file);
        expectColor(out.getPixel(150, 50), 255, 0, 0);
        expectColor(out.getPixel(150, 10), 0, 255, 0);
        expect((item.width, item.height), (200, 100));
      });
    });

    testWidgets("the filter is only on the photo, never on the markup", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          grid(200, 100),
          const EditState(filterIndex: 12, markup: [stroke]),
          PickerFilter.all[11].matrix,
          const OutputOptions(),
        );
        final out = await decode(item.file);
        expectColor(out.getPixel(150, 50), 255, 0, 0);
      });
    });

    testWidgets("markup outside the crop isn't in the file, inside it moves with the crop", (tester) async {
      await tester.runAsync(() async {
        const top = StrokeMark(points: [Offset(0, 0.1), Offset(1, 0.1)], color: red, width: 0.05);
        const bottom = StrokeMark(points: [Offset(0, 0.9), Offset(1, 0.9)], color: red, width: 0.05);
        final item = await service.export(
          grid(200, 100),
          const EditState(cropRect: Rect.fromLTWH(0, 0.5, 1, 0.5), markup: [top, bottom]),
          PickerFilter.identity,
          const OutputOptions(),
        );
        final out = await decode(item.file);
        // 0.9 of the whole is 0.8 of the bottom half
        expectColor(out.getPixel(150, 40), 255, 0, 0);
        expectColor(out.getPixel(150, 5), 255, 255, 255);
      });
    });

    testWidgets("text changes the pixels where it is", (tester) async {
      await tester.runAsync(() async {
        const text = TextMark(
          text: "WWW",
          color: Color(0xFF000000),
          center: Offset(0.75, 0.75),
          size: 0.1,
          background: TextBackground.solid,
        );
        final plain = await decode(
          (await service.export(
            grid(200, 100),
            const EditState(),
            PickerFilter.identity,
            const OutputOptions(),
          )).file,
        );
        final marked = await decode(
          (await service.export(
            grid(200, 100),
            const EditState(markup: [text]),
            PickerFilter.identity,
            const OutputOptions(),
          )).file,
        );
        var changed = 0;
        for (var y = 60; y < 90; y++) {
          for (var x = 120; x < 180; x++) {
            if ((plain.getPixel(x, y).r - marked.getPixel(x, y).r).abs() > 40) changed++;
          }
        }
        expect(changed, greaterThan(50));
        expectColor(marked.getPixel(10, 10), 255, 0, 0);
      });
    });

    testWidgets("markup skips the cache", (tester) async {
      await tester.runAsync(() async {
        final cache = FakeCacheService();
        final cached = ImageServiceImpl(root: dir.path, cache: cache);
        await cached.export(
          grid(20, 10),
          const EditState(markup: [stroke]),
          PickerFilter.identity,
          const OutputOptions(),
          cacheKey: "k",
        );
        expect(cache.writes, 0);
      });
    });
  });

  group("rotate and flip", () {
    testWidgets("a turn swaps the size and turns the colors counter clockwise", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          grid(200, 100),
          const EditState(turns: 1),
          PickerFilter.identity,
          const OutputOptions(),
        );
        expect((item.width, item.height), (100, 200));
        final out = await decode(item.file);
        expectColor(out.getPixel(10, 10), 0, 255, 0);
        expectColor(out.getPixel(90, 10), 255, 255, 255);
        expectColor(out.getPixel(10, 190), 255, 0, 0);
        expectColor(out.getPixel(90, 190), 0, 0, 255);
      });
    });

    testWidgets("a flip swaps left and right", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          grid(200, 100),
          const EditState(flipped: true),
          PickerFilter.identity,
          const OutputOptions(),
        );
        final out = await decode(item.file);
        expectColor(out.getPixel(10, 10), 0, 255, 0);
        expectColor(out.getPixel(190, 10), 255, 0, 0);
        expectColor(out.getPixel(10, 90), 255, 255, 255);
      });
    });

    testWidgets("the crop is of the image as shown after the turn", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          grid(200, 100),
          const EditState(turns: 1, cropRect: Rect.fromLTWH(0, 0, 1, 0.5)),
          PickerFilter.identity,
          const OutputOptions(),
        );
        expect((item.width, item.height), (100, 100));
        final out = await decode(item.file);
        expectColor(out.getPixel(10, 50), 0, 255, 0);
        expectColor(out.getPixel(90, 50), 255, 255, 255);
      });
    });

    testWidgets("markup on a turned image lands where the preview put it", (tester) async {
      await tester.runAsync(() async {
        const line = StrokeMark(
          points: [Offset(0, 0.1), Offset(1, 0.1)],
          color: Color(0xFF000000),
          width: 0.05,
        );
        final item = await service.export(
          grid(200, 100),
          const EditState(turns: 1, markup: [line]),
          PickerFilter.identity,
          const OutputOptions(),
        );
        final out = await decode(item.file);
        expectColor(out.getPixel(50, 20), 0, 0, 0);
        expectColor(out.getPixel(10, 60), 0, 255, 0);
      });
    });
  });

  group("format", () {
    /// the left half see through, the right half red.
    XFile halfClear() {
      final image = img.Image(width: 40, height: 20, numChannels: 4);
      for (final pixel in image) {
        pixel
          ..r = 255
          ..a = pixel.x < 20 ? 0 : 255;
      }
      final file = File("${dir.path}/clear.png")..writeAsBytesSync(img.encodePng(image));
      return XFile(file.path);
    }

    testWidgets("png keeps transparency and says it's a png", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          halfClear(),
          const EditState(cropRect: Rect.fromLTWH(0, 0, 1, 0.5)),
          PickerFilter.identity,
          const OutputOptions(format: OutputFormat.png),
        );
        expect(item.file.path, endsWith(".png"));
        expect(item.file.mimeType, "image/png");
        final out = img.decodePng(await item.file.readAsBytes())!;
        expect(out.getPixel(5, 5).a, 0);
        expect(out.getPixel(35, 5).a, 255);
        expect(out.getPixel(35, 5).r, closeTo(255, 2));
      });
    });

    testWidgets("jpeg puts white behind the transparent part", (tester) async {
      await tester.runAsync(() async {
        final item = await service.export(
          halfClear(),
          const EditState(cropRect: Rect.fromLTWH(0, 0, 1, 0.5)),
          PickerFilter.identity,
          const OutputOptions(),
        );
        expect(item.file.path, endsWith(".jpg"));
        final out = await decode(item.file);
        expectColor(out.getPixel(5, 5), 255, 255, 255);
        expectColor(out.getPixel(35, 5), 255, 0, 0);
      });
    });

    testWidgets("png gets under a max size by scaling down", (tester) async {
      await tester.runAsync(() async {
        final source = grid(400, 400);
        final full = await service.export(
          source,
          const EditState(),
          PickerFilter.all[11].matrix,
          const OutputOptions(format: OutputFormat.png),
        );
        final limit = await full.file.length() ~/ 3;
        final limited = await service.export(
          source,
          const EditState(),
          PickerFilter.all[11].matrix,
          OutputOptions(format: OutputFormat.png, maxBytes: limit),
        );
        expect(limited.width, lessThan(400));
        expect(limited.file.path, endsWith(".png"));
        expect(await limited.file.length() <= limit || limited.overLimit, isTrue);
      });
    });
  });
}
