import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/models/album.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_gallery_service.dart';

void main() {
  GalleryController controllerFor(FakeGalleryService gallery, {int max = 1}) => GalleryController(
    service: gallery,
    settings: PickerSettings(maxSelection: max),
  );

  test("loads page 0 with size 80 and previews the first item", () async {
    final gallery = FakeGalleryService.withItems(200);
    final controller = controllerFor(gallery);
    await controller.init();
    expect(gallery.pageCalls, [("all", 0)]);
    expect(controller.items.value.length, GalleryController.pageSize);
    expect(controller.state.value, GalleryState.ready);
    expect(controller.preview.value?.id, "0");
    expect(controller.selection.value.map((e) => e.id), ["0"]);
  });

  test("loadMore never loads the same page twice and stops at the end", () async {
    final gallery = FakeGalleryService.withItems(200);
    final controller = controllerFor(gallery);
    await controller.init();
    await Future.wait([controller.loadMore(), controller.loadMore()]);
    await controller.loadMore();
    await controller.loadMore();
    expect(gallery.pageCalls, [("all", 0), ("all", 1), ("all", 2)]);
    expect(controller.items.value.length, 200);
    expect(controller.ended.value, isTrue);
  });

  test("an extra item over the max isn't added", () async {
    final gallery = FakeGalleryService.withItems(10);
    final controller = controllerFor(gallery, max: 2);
    await controller.init();
    final items = controller.items.value;
    expect(controller.toggle(items[1]), isTrue);
    expect(controller.toggle(items[2]), isFalse);
    expect(controller.selection.value.map((e) => e.id), ["0", "1"]);
    expect(controller.orderOf(items[1]), 2);
    expect(controller.orderOf(items[2]), 0);
  });

  test("tap on the shown selected item removes it, on another selected one shows it", () async {
    final gallery = FakeGalleryService.withItems(10);
    final controller = controllerFor(gallery, max: 3);
    await controller.init();
    final items = controller.items.value;
    controller.toggle(items[1]);
    expect(controller.preview.value, items[1]);

    controller.toggle(items[0]);
    expect(controller.preview.value, items[0]);
    expect(controller.selection.value.length, 2);

    controller.toggle(items[0]);
    expect(controller.selection.value, [items[1]]);
    expect(controller.preview.value, items[1]);
  });

  test("single selection replaces the item", () async {
    final gallery = FakeGalleryService.withItems(10);
    final controller = controllerFor(gallery);
    await controller.init();
    final items = controller.items.value;
    expect(controller.toggle(items[3]), isTrue);
    expect(controller.selection.value, [items[3]]);
    expect(controller.preview.value, items[3]);
  });

  test("selection is kept in order across album switch", () async {
    final gallery = FakeGalleryService(
      data: {"all": List.generate(10, (i) => fakeItem("a$i")), "other": List.generate(5, (i) => fakeItem("b$i"))},
    );
    final controller = controllerFor(gallery, max: 5);
    await controller.init();
    controller.toggle(controller.items.value[2]);
    await controller.switchAlbum(const Album(id: "other", name: "other", count: 5));
    controller.toggle(controller.items.value[1]);
    expect(controller.selection.value.map((e) => e.id), ["a0", "a2", "b1"]);
    expect(controller.items.value.first.id, "b0");
  });

  test("preview stays on the selected item when a page loads", () async {
    final gallery = FakeGalleryService.withItems(200);
    final controller = controllerFor(gallery, max: 3);
    await controller.init();
    controller.toggle(controller.items.value[5]);
    await controller.loadMore();
    expect(controller.preview.value?.id, "5");
  });

  test("a gallery change reloads and drops selected items that are gone", () async {
    final gallery = FakeGalleryService.withItems(10);
    final controller = controllerFor(gallery, max: 3);
    await controller.init();
    controller.toggle(controller.items.value[4]);
    gallery.data["all"]!.removeAt(4);
    gallery.emitChange();
    await pumpEventQueue();
    expect(controller.items.value.length, 9);
    expect(controller.selection.value.map((e) => e.id), ["0"]);
    expect(controller.preview.value?.id, "0");
  });

  test("an old page result is dropped after an album switch", () async {
    final gallery = FakeGalleryService(
      data: {"all": List.generate(10, (i) => fakeItem("a$i")), "other": List.generate(5, (i) => fakeItem("b$i"))},
    );
    final controller = controllerFor(gallery);
    final gate = Completer<void>();
    gallery.itemsGate = gate;
    final init = controller.init();
    await pumpEventQueue();
    gallery.itemsGate = null;
    await controller.switchAlbum(const Album(id: "other", name: "other", count: 5));
    gate.complete();
    await init;
    expect(controller.items.value.map((e) => e.id), everyElement(startsWith("b")));
  });

  test("access states", () async {
    final denied = controllerFor(FakeGalleryService.withItems(5, access: GalleryAccess.denied));
    await denied.init();
    expect(denied.state.value, GalleryState.denied);

    final limited = controllerFor(FakeGalleryService.withItems(5, access: GalleryAccess.limited));
    await limited.init();
    expect(limited.state.value, GalleryState.ready);
    expect(limited.access.value, GalleryAccess.limited);

    final empty = controllerFor(FakeGalleryService.withItems(0));
    await empty.init();
    expect(empty.state.value, GalleryState.empty);

    final noAlbums = controllerFor(FakeGalleryService(data: {}));
    await noAlbums.init();
    expect(noAlbums.state.value, GalleryState.empty);
  });

  test("picked items keep the selection order", () async {
    final gallery = FakeGalleryService.withItems(10);
    final controller = controllerFor(gallery, max: 3);
    await controller.init();
    controller.toggle(controller.items.value[7]);
    controller.toggle(controller.items.value[3]);
    final picked = await controller.pickedItems();
    expect(picked.map((e) => e.file.path), ["/fake/0", "/fake/7", "/fake/3"]);
    expect(picked.every((e) => !e.edited), isTrue);
    controller.dispose();
  });
}
