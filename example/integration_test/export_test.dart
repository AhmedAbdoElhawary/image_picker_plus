import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
import 'package:integration_test/integration_test.dart';

/// the times and the memory a photo export takes, printed by the driver. profile mode, a debug
/// build is slow enough to mean nothing:
/// flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/export_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp("export_test"));
  tearDown(() => dir.delete(recursive: true));

  /// a jpeg like the gallery gives, a png would decode a lot slower.
  Future<XFile> source(int width, int height, Future<ByteData> Function(int, int) draw) async {
    final file = File("${dir.path}/source_$width.jpg")
      ..writeAsBytesSync(await encodeJpeg(draw, width, height, 95));
    return XFile(file.path);
  }

  /// the most memory the process holds over [body], over what it held before it.
  Future<int> extraMegabytes(Future<void> Function() body) async {
    final before = ProcessInfo.currentRss;
    var peak = before;
    final sampler = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => peak = max(peak, ProcessInfo.currentRss),
    );
    await body();
    sampler.cancel();
    return (peak - before) >> 20;
  }

  /// the worst case for memory: the crop wants the photo at full size, and the whole of it is
  /// what the engine decodes. [ImageServiceImpl.maxDecodePixels] is what keeps it down.
  /// first, making a photo this big takes memory of its own and the test below keeps 50 mb.
  testWidgets("a tight crop of a 27 mp photo stays within the decode cap", (tester) async {
    // the rows are made as they're asked for, a photo this big of them at once wouldn't fit
    final photo = await source(6000, 4500, (top, rows) => _strip(6000, top, rows));
    final service = ImageServiceImpl(root: dir.path);
    final memory = <int>[];
    for (var i = 0; i < 2; i++) {
      memory.add(
        await extraMegabytes(
          () => service.export(
            photo,
            const EditState(cropRect: Rect.fromLTWH(0.4, 0.4, 0.2, 0.2)),
            PickerFilter.identity,
            const OutputOptions(),
          ),
        ),
      );
    }
    binding.reportData = {...?binding.reportData, "crop_extra_mb": memory};
    debugPrint("tight crop extra memory mb $memory");
  });

  testWidgets("a 12 mp photo exports fast and light", (tester) async {
    const width = 4096;
    const height = 3072;
    // made once here, the three encodes and the source jpeg all read the same pixels
    final pixels = (await _strip(width, 0, height)).buffer.asUint8List();
    Future<ByteData> strip(int top, int rows) async =>
        ByteData.sublistView(pixels, top * width * 4, (top + rows) * width * 4);

    final encodes = <int>[];
    for (var i = 0; i < 3; i++) {
      final watch = Stopwatch()..start();
      await encodeJpeg(strip, width, height, 90);
      encodes.add(watch.elapsedMilliseconds);
    }

    final photo = await source(width, height, strip);
    final service = ImageServiceImpl(root: dir.path);
    final exports = <int>[];
    final memory = <int>[];
    for (var i = 0; i < 3; i++) {
      final watch = Stopwatch()..start();
      memory.add(
        await extraMegabytes(
          () => service.export(
            photo,
            const EditState(filterIndex: 1),
            PickerFilter.all.first.matrix,
            const OutputOptions(),
          ),
        ),
      );
      exports.add(watch.elapsedMilliseconds);
    }
    // at the default 2048 the photo is about 1 mb, so 300 kb needs a lower quality and a smaller size
    final limited = <int>[];
    for (var i = 0; i < 2; i++) {
      final watch = Stopwatch()..start();
      await service.export(
        photo,
        const EditState(filterIndex: 1),
        PickerFilter.all.first.matrix,
        const OutputOptions(maxBytes: 300 << 10),
      );
      limited.add(watch.elapsedMilliseconds);
    }

    binding.reportData = {
      ...?binding.reportData,
      "encode_ms": encodes,
      "export_ms": exports,
      "export_extra_mb": memory,
      "export_limit_ms": limited,
    };
    debugPrint(
      "encode ms $encodes, full export ms $exports, extra memory mb $memory, size limit ms $limited",
    );
  });
}

/// [rows] of a photo from [top]: noise over gradients, so the jpeg is about the size of a real
/// photo's. plain int math, a 27 mp one of these is slow enough already.
Future<ByteData> _strip(int width, int top, int rows) async {
  final pixels = Uint8List(width * rows * 4);
  for (var row = 0; row < rows; row++) {
    final y = top + row;
    for (var x = 0; x < width; x++) {
      final i = (row * width + x) * 4;
      final noise = (x * 2654435761 + y * 1597334677) & 31;
      pixels
        ..[i] = (x * 255 ~/ width + noise) & 255
        ..[i + 1] = (y * 255 ~/ width + noise) & 255
        ..[i + 2] = (x ~/ 60 * 29 + y ~/ 45 * 53 + noise) & 255
        ..[i + 3] = 255;
    }
  }
  return ByteData.sublistView(pixels);
}
