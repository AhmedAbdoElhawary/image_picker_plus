import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

void main() {
  PickedItem roundTrip(PickedItem item) =>
      PickedItem.fromMap((jsonDecode(jsonEncode(item.toMap())) as Map).cast<String, Object?>());

  test("original is the file itself when not given", () {
    final file = XFile("/a.jpg");
    final item = PickedItem(file: file, type: MediaType.image, width: 1, height: 1, edited: false);
    expect(identical(item.original, file), isTrue);
    expect(item.overLimit, isFalse);
  });

  test("an edited image survives a json round trip", () {
    final item = PickedItem(
      file: XFile("/tmp/edit.jpg"),
      type: MediaType.image,
      width: 100,
      height: 80,
      edited: true,
      id: "asset-1",
      original: XFile("/photos/IMG_1.HEIC"),
      edit: const EditState(
        cropRect: Rect.fromLTWH(0, 0.1, 1, 0.8),
        ratio: CropRatio.landscape,
        filterIndex: 2,
      ),
      overLimit: true,
    );
    final map = item.toMap();
    expect(map["v"], 1);
    final back = roundTrip(item);
    expect(back.file.path, "/tmp/edit.jpg");
    expect(back.original.path, "/photos/IMG_1.HEIC");
    expect(
      (back.type, back.width, back.height, back.edited, back.id),
      (MediaType.image, 100, 80, true, "asset-1"),
    );
    expect(back.edit, item.edit);
    expect(back.overLimit, isTrue);
  });

  test("a map with only the file loads with defaults", () {
    final item = PickedItem.fromMap(const {"file": "/a.jpg"});
    expect((item.type, item.width, item.height, item.edited, item.id), (MediaType.image, 0, 0, false, null));
    expect(identical(item.original, item.file), isTrue);
    expect(item.edit, const EditState());
  });

  test("a video has no edit state", () {
    final video = PickedItem(
      file: XFile("/v.mp4"),
      type: MediaType.video,
      width: 1,
      height: 1,
      edited: false,
    );
    expect(video.toMap().containsKey("edit"), isFalse);
    expect(roundTrip(video).edit, isNull);
    expect(roundTrip(video).type, MediaType.video);
  });
}
