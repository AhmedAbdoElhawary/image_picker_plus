import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/export_item.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  final photo = fakeItem("a");
  final video = fakeItem("v", type: MediaType.video);
  const cropped = EditState(cropRect: Rect.fromLTWH(0, 0, 0.5, 1));

  MediaItem taken(String path, {int width = 400}) => MediaItem(
    id: path,
    path: path,
    type: MediaType.image,
    width: width,
    height: 300,
    modified: DateTime(2026),
  );

  test("an unedited gallery image is the gallery file with its id and an empty edit", () async {
    final fakes = Fakes();
    final item = (await exportItem(services: fakes.services, output: const OutputOptions(), item: photo))!;
    expect(item.file.path, "/fake/a");
    expect(identical(item.original, item.file), isTrue);
    expect((item.id, item.edit, item.edited), ("a", const EditState(), false));
    expect(fakes.image.calls, isEmpty);
  });

  test("an edited image is exported and keeps its original and edit", () async {
    final fakes = Fakes();
    final item = (await exportItem(
      services: fakes.services,
      output: const OutputOptions(),
      item: photo,
      state: cropped,
    ))!;
    expect(item.file.path, "/fake/a.edited.jpg");
    expect(item.original.path, "/fake/a");
    expect((item.id, item.edit, item.edited), ("a", cropped, true));
  });

  test("a video has no edit state and is never exported", () async {
    final fakes = Fakes();
    final item = (await exportItem(
      services: fakes.services,
      output: const OutputOptions(maxWidth: 1),
      item: video,
    ))!;
    expect((item.edit, item.edited, item.file.path), (null, false, "/fake/v"));
    expect(fakes.image.calls, isEmpty);
  });

  test("a gallery item with no file anymore gives null", () async {
    final fakes = Fakes(gallery: _NoFiles());
    expect(await exportItem(services: fakes.services, output: const OutputOptions(), item: photo), isNull);
  });

  test("an edited gallery image reads the original and the editable file in parallel", () async {
    final fakes = Fakes();
    await exportItem(services: fakes.services, output: const OutputOptions(), item: photo, state: cropped);
    expect(fakes.gallery.fileCalls, unorderedEquals([("a", false), ("a", true)]));
  });

  test("a camera photo has no id and its original is its path", () async {
    final fakes = Fakes();
    final item = (await exportItem(
      services: fakes.services,
      output: const OutputOptions(),
      item: taken("/cam/1.jpg"),
      state: cropped,
    ))!;
    expect(item.id, isNull);
    expect(item.original.path, "/cam/1.jpg");
    expect(fakes.gallery.fileCalls, isEmpty);
  });

  group("limits on unedited images", () {
    test("no limits never re-encodes", () async {
      final fakes = Fakes();
      await exportItem(
        services: fakes.services,
        output: const OutputOptions(),
        item: taken("/cam/big.jpg", width: 9000),
      );
      expect(fakes.image.calls, isEmpty);
    });

    test("over max width is re-encoded, not reported edited, with the original attached", () async {
      final fakes = Fakes();
      final item = (await exportItem(
        services: fakes.services,
        output: const OutputOptions(maxWidth: 100),
        item: taken("/cam/1.jpg"),
      ))!;
      expect(fakes.image.calls.single.$2, const EditState());
      expect(item.file.path, "/cam/1.jpg.edited.jpg");
      expect(item.original.path, "/cam/1.jpg");
      expect((item.edited, item.edit), (false, const EditState()));
    });

    test("under max width comes back untouched", () async {
      final fakes = Fakes();
      final item = (await exportItem(
        services: fakes.services,
        output: const OutputOptions(maxWidth: 1000, maxHeight: 1000),
        item: taken("/cam/1.jpg"),
      ))!;
      expect(fakes.image.calls, isEmpty);
      expect(identical(item.file, item.original), isTrue);
    });

    test("max bytes reads the file size", () async {
      final dir = Directory.systemTemp.createTempSync("export_item_test");
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File("${dir.path}/1.jpg")..writeAsBytesSync(List.filled(1000, 0));
      final fakes = Fakes();
      await exportItem(
        services: fakes.services,
        output: const OutputOptions(maxBytes: 2000),
        item: taken(file.path),
      );
      expect(fakes.image.calls, isEmpty);
      await exportItem(
        services: fakes.services,
        output: const OutputOptions(maxBytes: 500),
        item: taken(file.path),
      );
      expect(fakes.image.calls, hasLength(1));
    });

    test("an unedited gallery image over a limit is exported from the editable file", () async {
      final fakes = Fakes();
      await exportItem(services: fakes.services, output: const OutputOptions(maxWidth: 100), item: photo);
      expect(fakes.gallery.fileCalls, [("a", false), ("a", true)]);
      expect(fakes.image.keys.single, isNull);
    });
  });

  test("an image that can't fit comes back flagged", () async {
    final fakes = Fakes()..image.overLimit = true;
    final item = (await exportItem(
      services: fakes.services,
      output: const OutputOptions(maxBytes: 10),
      item: photo,
      state: cropped,
    ))!;
    expect(item.overLimit, isTrue);
    expect(fakes.image.outputs.single.maxBytes, 10);
  });

  test("an unedited image over a limit is re-encoded in the chosen format, its original kept", () async {
    final fakes = Fakes();
    final item = (await exportItem(
      services: fakes.services,
      output: const OutputOptions(format: OutputFormat.png, maxWidth: 100),
      item: taken("/files/big.png"),
    ))!;
    expect(fakes.image.outputs.single.format, OutputFormat.png);
    expect((item.edited, item.original.path), (false, "/files/big.png"));
  });

  test("the filter and the sliders go out as one matrix", () async {
    final fakes = Fakes();
    const state = EditState(filterIndex: 1, adjustments: Adjustments(brightness: 0.5));
    await exportItem(
      services: fakes.services,
      output: const OutputOptions(),
      filters: PickerFilter.all,
      item: photo,
      state: state,
    );
    expect(fakes.image.matrices.single, composeMatrix(PickerFilter.all.first.matrix, state.adjustments));
  });
}

class _NoFiles extends FakeGalleryService {
  @override
  Future<XFile?> file(MediaItem item, {bool editable = false}) async => null;
}
