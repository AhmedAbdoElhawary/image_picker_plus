import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
import 'package:integration_test/integration_test.dart';

/// flutter test integration_test/export_test.dart on a phone, the numbers are printed.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("a 12 mp photo exports fast and light", (tester) async {
    const width = 4096;
    const height = 3072;
    final pixels = _photo(width, height);
    Future<ByteData> strip(int top, int rows) async =>
        ByteData.sublistView(pixels, top * width * 4, (top + rows) * width * 4);

    final encodes = <int>[];
    for (var i = 0; i < 3; i++) {
      final watch = Stopwatch()..start();
      await encodeJpeg(strip, width, height, 90);
      encodes.add(watch.elapsedMilliseconds);
    }

    final dir = await Directory.systemTemp.createTemp("export_test");
    // a jpeg like the gallery gives, a png would decode a lot slower
    final source = File("${dir.path}/source.jpg")
      ..writeAsBytesSync(await encodeJpeg(strip, width, height, 95));
    final service = ImageServiceImpl(root: dir.path);
    final exports = <int>[];
    final memory = <int>[];
    for (var i = 0; i < 3; i++) {
      final before = ProcessInfo.currentRss;
      var peak = before;
      final sampler = Timer.periodic(
        const Duration(milliseconds: 10),
        (_) => peak = max(peak, ProcessInfo.currentRss),
      );
      final watch = Stopwatch()..start();
      await service.export(
        XFile(source.path),
        const EditState(filterIndex: 1),
        PickerFilter.all.first.matrix,
        const OutputOptions(),
      );
      exports.add(watch.elapsedMilliseconds);
      sampler.cancel();
      memory.add((peak - before) >> 20);
    }
    // the photo is about 3.6 mb, so 1 mb needs a lower quality and a smaller size
    final limited = <int>[];
    for (var i = 0; i < 2; i++) {
      final watch = Stopwatch()..start();
      await service.export(
        XFile(source.path),
        const EditState(filterIndex: 1),
        PickerFilter.all.first.matrix,
        const OutputOptions(maxBytes: 1 << 20),
      );
      limited.add(watch.elapsedMilliseconds);
    }
    await dir.delete(recursive: true);

    binding.reportData = {
      ...?binding.reportData,
      "encode_ms": encodes,
      "export_ms": exports,
      "export_extra_mb": memory,
      "export_1mb_ms": limited,
    };
    debugPrint(
      "encode ms $encodes, full export ms $exports, extra memory mb $memory, 1 mb limit ms $limited",
    );
  });
}

/// noise over gradients, so the jpeg is about the size of a real photo's.
Uint8List _photo(int width, int height) {
  final random = Random(1);
  final pixels = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final noise = random.nextInt(24);
      pixels
        ..[i] = (x * 255 ~/ width + noise).clamp(0, 255)
        ..[i + 1] = (y * 255 ~/ height + noise).clamp(0, 255)
        ..[i + 2] = (128 + 100 * sin(x / 60) * cos(y / 45) + noise).toInt().clamp(0, 255)
        ..[i + 3] = 255;
    }
  }
  return pixels;
}
