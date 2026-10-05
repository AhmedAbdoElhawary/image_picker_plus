import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/gallery/preselection.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/markup_options.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_files_service.dart';
import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

PickedItem fromGallery(String id, {MediaType type = MediaType.image, EditState? edit}) => PickedItem(
  file: XFile("/fake/$id"),
  type: type,
  width: 400,
  height: 300,
  edited: false,
  id: id,
  edit: edit,
);

PickedItem fromFile(String path) =>
    PickedItem(file: XFile(path), type: MediaType.image, width: 400, height: 300, edited: false);

void main() {
  late Fakes fakes;
  setUp(() {
    fakes = Fakes(
      gallery: FakeGalleryService(
        data: {
          "all": [for (var i = 0; i < 10; i++) fakeItem("$i"), fakeItem("v", type: MediaType.video)],
        },
      ),
    );
  });

  Future<Preselection> resolve(List<PickedItem> selected, {int max = 10, MediaType type = MediaType.all}) =>
      Preselection.resolve(
        services: fakes.services,
        settings: PickerSettings(maxSelection: max, mediaType: type),
        selected: selected,
      );

  test("keeps the order and loads no album page", () async {
    final result = await resolve([fromGallery("3"), fromGallery("1"), fromGallery("7")]);
    expect(result.items.map((e) => e.id), ["3", "1", "7"]);
    expect(result.skipped, isFalse);
    expect(fakes.gallery.pageCalls, isEmpty);
  });

  test("cuts to the max before looking anything up", () async {
    final result = await resolve([for (var i = 0; i < 5; i++) fromGallery("$i")], max: 3);
    expect(result.items.map((e) => e.id), ["0", "1", "2"]);
    expect(fakes.gallery.itemCalls, 3);
    expect(result.skipped, isFalse);
  });

  test("a gone item or the wrong type is skipped", () async {
    fakes.gallery.gone.add("1");
    final result = await resolve([
      fromGallery("0"),
      fromGallery("1"),
      fromGallery("v", type: MediaType.video),
    ], type: MediaType.image);
    expect(result.items.map((e) => e.id), ["0"]);
    expect(result.skipped, isTrue);
  });

  test("the same item twice is kept once, at its first place", () async {
    final result = await resolve([fromGallery("2"), fromGallery("5"), fromGallery("2")]);
    expect(result.items.map((e) => e.id), ["2", "5"]);
    expect(result.skipped, isFalse);
  });

  test("camera and system picker files are read from their original", () async {
    final files = FakeFilesService(unreadable: {"/gone.jpg"});
    fakes = Fakes(gallery: fakes.gallery, files: files);
    final result = await resolve([fromFile("/cam/1.jpg"), fromFile("/gone.jpg")]);
    expect(result.items.single.path, "/cam/1.jpg");
    expect(result.skipped, isTrue);
  });

  test("gallery ids are skipped where there's no gallery", () async {
    final services = fakes.services;
    final result = await Preselection.resolve(
      services: PickerServices(
        gallery: null,
        camera: services.camera,
        image: services.image,
        files: services.files,
      ),
      settings: const PickerSettings(maxSelection: 5),
      selected: [fromGallery("0"), fromFile("/picked/1.jpg")],
    );
    expect(result.items.single.path, "/picked/1.jpg");
    expect(result.skipped, isTrue);
  });

  test("edits are kept per image id", () async {
    const edit = EditState(filterIndex: 4);
    final result = await resolve([fromGallery("0", edit: edit), fromGallery("1")]);
    expect(result.edits, {"0": edit});
  });

  group("restore", () {
    const square = EditState(
      cropRect: Rect.fromLTWH(0.2, 0, 0.75, 1),
      ratio: CropRatio.square,
      filterIndex: 3,
    );

    Future<Preselection> one(EditState edit) => resolve([fromGallery("0", edit: edit)]);

    test("a ratio still offered keeps its rect", () async {
      final (crops, filters, _) = (await one(square)).restore(ratios: CropRatio.all, filters: true);
      expect(crops["0"]!.ratio, CropRatio.square);
      expect(crops["0"]!.value, square.cropRect);
      expect(filters["0"]!.value, 3);
    });

    test("a removed ratio falls back to the first one, centred", () async {
      final (crops, _, _) = (await one(square)).restore(ratios: const [CropRatio.portrait], filters: false);
      final crop = crops["0"]!;
      expect(crop.ratio, CropRatio.portrait);
      expect(crop.value.center.dx, closeTo(0.5, 0.001));
    });

    test("only original offered keeps only an original crop", () async {
      const original = EditState(cropRect: Rect.fromLTWH(0, 0, 1, 1), ratio: CropRatio.original);
      final (kept, _, _) = (await one(original)).restore(ratios: const [CropRatio.original], filters: false);
      expect(kept["0"]!.ratio, CropRatio.original);
      final (reset, _, _) = (await one(square)).restore(ratios: const [CropRatio.original], filters: false);
      expect(reset["0"]!.value, isNot(square.cropRect));
    });

    test("crop off or filters off restores nothing for them", () async {
      final (crops, filters, _) = (await one(square)).restore(ratios: const [], filters: false);
      expect(crops, isEmpty);
      expect(filters, isEmpty);
    });

    test("a filter out of range is no filter", () async {
      final (_, filters, _) = (await one(
        const EditState(filterIndex: 99),
      )).restore(ratios: const [], filters: true);
      expect(filters["0"]!.value, 0);
    });
  });

  test("markup comes back when it's on, a sticker that's gone is dropped", () async {
    const text = TextMark(text: "Hi", color: Color(0xFF000000), center: Offset(0.5, 0.5), size: 0.1);
    const sticker = StickerMark(index: 3, center: Offset(0.5, 0.5), width: 0.2);
    final preselection = await resolve([
      fromGallery("0", edit: const EditState(markup: [text, sticker])),
    ]);
    final (_, _, markups) = preselection.restore(
      ratios: const [],
      filters: false,
      markup: const MarkupOptions(text: true, stickers: []),
    );
    expect(markups["0"]!.value, [text]);
    final (_, _, off) = preselection.restore(ratios: const [], filters: false);
    expect(off, isEmpty);
  });
}
