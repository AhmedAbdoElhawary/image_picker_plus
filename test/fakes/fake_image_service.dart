import 'dart:async';

import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/image_service.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class FakeImageService implements ImageService {
  final List<(String, EditState)> calls = [];
  final List<String?> keys = [];
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<PickedItem> export(
    XFile source,
    EditState state,
    List<double> colorMatrix,
    OutputOptions output, {
    String? cacheKey,
  }) async {
    await gate?.future;
    if (fail) throw Exception("export failed");
    calls.add((source.path, state));
    keys.add(cacheKey);
    return PickedItem(
      file: XFile("${source.path}.edited.jpg"),
      type: MediaType.image,
      width: 100,
      height: 100,
      edited: true,
    );
  }
}
