import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  final a = fakeItem("a");
  final b = fakeItem("b");
  final v = fakeItem("v", type: MediaType.video);

  EditController controllerFor(Fakes fakes, {Map<String, CropController> crops = const {}}) => EditController(
    services: fakes.services,
    output: const OutputOptions(quality: 80),
    items: [a, v, b],
    crops: crops,
    filterIndexes: {"a": ValueNotifier(0), "b": ValueNotifier(0)},
  );

  test("one state per image and none for videos", () {
    final crop = CropController(imageAspect: 2, ratio: CropRatio.square);
    final controller = controllerFor(Fakes(), crops: {"b": crop});
    expect(controller.stateOf(a), isNotNull);
    expect(controller.stateOf(v), isNull);
    expect(controller.stateOf(b)!.cropRect.width, 0.5);
    expect(controller.current.value, a);
  });

  test("the crop is the shared one, so a change shows on the page that opened it", () {
    final crop = CropController(imageAspect: 2, ratio: CropRatio.square);
    final controller = controllerFor(Fakes(), crops: {"b": crop});
    crop.pan(const Offset(-1, 0));
    expect(controller.stateOf(b)!.cropRect.left, 0);
  });

  test("filter is per image and does nothing on a video", () {
    final controller = controllerFor(Fakes());
    controller.setFilter(3);
    expect(controller.stateOf(a)!.filterIndex, 3);
    expect(controller.stateOf(b)!.filterIndex, 0);
    controller.current.value = v;
    controller.setFilter(2);
    expect(controller.stateOf(v), isNull);
  });

  test("reorder moves the items and their states together", () {
    final controller = controllerFor(Fakes());
    controller.setFilter(4);
    controller.reorder(0, 2);
    expect(controller.items.value, [v, b, a]);
    expect(controller.stateOf(a)!.filterIndex, 4);
  });

  test("export keeps the order, returns videos untouched and exports only edited images", () async {
    final fakes = Fakes();
    final controller = controllerFor(fakes);
    controller.current.value = b;
    controller.setFilter(1);
    controller.reorder(2, 0);
    final picked = await controller.export();
    expect(picked.map((e) => e.file.path), ["/fake/b.edited.jpg", "/fake/a", "/fake/v"]);
    expect(picked.map((e) => e.edited), [true, false, false]);
    expect(picked[2].type, MediaType.video);
    expect(fakes.image.calls.single.$1, "/fake/b");
    expect(fakes.image.keys.single, contains("edit:b:"));
    expect(controller.exporting.value, isFalse);
  });

  test("a failed export stops the progress and throws", () async {
    final fakes = Fakes()..image.fail = true;
    final controller = controllerFor(fakes);
    controller.setFilter(1);
    await expectLater(controller.export(), throwsException);
    expect(controller.exporting.value, isFalse);
    controller.dispose();
  });
}
