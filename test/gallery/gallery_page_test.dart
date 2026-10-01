import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/gallery/gallery_cell.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';

import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  Finder cell(String id) => find.byKey(ValueKey(id));

  testWidgets("the grid shows the items", (tester) async {
    await pumpPicker(tester, const GalleryPage(), fakes: Fakes(gallery: FakeGalleryService.withItems(30)));
    expect(find.byType(GalleryCell), findsWidgets);
    expect(cell("0"), findsOneWidget);
  });

  testWidgets("tap shows the order badge, and past the max shows the message", (tester) async {
    await pumpPicker(
      tester,
      const GalleryPage(),
      fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
      settings: const PickerSettings(maxSelection: 2),
    );
    expect(find.text("1"), findsOneWidget);
    await tester.tap(cell("1"));
    await tester.pumpAndSettle();
    expect(find.text("2"), findsOneWidget);

    await tester.tap(cell("2"));
    await tester.pump();
    expect(find.text("You can select up to 2 items"), findsOneWidget);
  });

  testWidgets("denied shows the message with open settings and close", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(5, access: GalleryAccess.denied));
    Object? result = "not closed";
    await pumpPicker(tester, const GalleryPage(), fakes: fakes, onResult: (r) => result = r);
    expect(find.byType(MessageView), findsOneWidget);
    expect(find.text("Allow access to your photos to continue"), findsOneWidget);

    await tester.tap(find.text("Open settings"));
    expect(fakes.gallery.openSettingsCalls, 1);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets("empty shows no images with close", (tester) async {
    await pumpPicker(tester, const GalleryPage(), fakes: Fakes(gallery: FakeGalleryService.withItems(0)));
    expect(find.text("There are no images"), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets("limited shows manage access", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(5, access: GalleryAccess.limited));
    await pumpPicker(tester, const GalleryPage(), fakes: fakes);
    await tester.tap(find.text("Manage access"));
    await tester.pumpAndSettle();
    expect(fakes.gallery.manageCalls, 1);
  });

  testWidgets("next pops the picked items in order", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      const GalleryPage(),
      fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
      settings: const PickerSettings(maxSelection: 3),
      onResult: (r) => result = r,
    );
    await tester.tap(cell("5"));
    await tester.tap(cell("2"));
    await tester.pump();
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    final items = result! as List<PickedItem>;
    expect(items.map((e) => e.file.path), ["/fake/0", "/fake/5", "/fake/2"]);
  });

  testWidgets("close pops null", (tester) async {
    Object? result = "not closed";
    await pumpPicker(tester, const GalleryPage(), onResult: (r) => result = r);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets("scrolling to the end loads the next page", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(200));
    await pumpPicker(tester, const GalleryPage(), fakes: fakes);
    await tester.fling(find.byType(GridView), const Offset(0, -3000), 3000);
    await tester.pumpAndSettle();
    expect(fakes.gallery.pageCalls.length, greaterThan(1));
  });

  testWidgets("switching album from the sheet", (tester) async {
    final gallery = FakeGalleryService(
      data: {"all": List.generate(10, (i) => fakeItem("a$i")), "Camera": List.generate(3, (i) => fakeItem("b$i"))},
    );
    await pumpPicker(tester, const GalleryPage(), fakes: Fakes(gallery: gallery));
    expect(find.text("Recent"), findsOneWidget);
    await tester.tap(find.text("Recent"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Camera"));
    await tester.pumpAndSettle();
    expect(cell("b0"), findsOneWidget);
    expect(cell("a1"), findsNothing);
  });

  testWidgets("crop in the preview, then next opens the edit page and done returns the crop", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(10));
    Object? result;
    await pumpPicker(
      tester,
      const GalleryPage(),
      fakes: fakes,
      settings: const PickerSettings(cropRatios: [CropRatio.square, CropRatio.portrait]),
      onResult: (r) => result = r,
    );
    expect(find.byType(CropView), findsOneWidget);
    expect(find.text("1:1"), findsOneWidget);
    await tester.tap(find.text("1:1"));
    await tester.pump();
    expect(find.text("4:5"), findsOneWidget);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    expect(find.byType(EditPage), findsOneWidget);
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    final items = result! as List<PickedItem>;
    expect(items.single.edited, isTrue);
    final rect = fakes.image.calls.single.$2.cropRect;
    // 4:5 of a 400x300 image
    expect(rect.width * 400 / (rect.height * 300), closeTo(0.8, 1e-6));
  });

  testWidgets("back from the edit page keeps the picker open", (tester) async {
    Object? result = "open";
    await pumpPicker(
      tester,
      const GalleryPage(),
      settings: const PickerSettings(filters: true),
      onResult: (r) => result = r,
    );
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(GalleryPage), findsOneWidget);
    expect(result, "open");
  });

  testWidgets("dragging the crop moves it", (tester) async {
    await pumpPicker(tester, const GalleryPage(), settings: const PickerSettings(cropRatios: [CropRatio.square]));
    final view = tester.widget<CropView>(find.byType(CropView));
    final before = view.controller.value;
    await tester.drag(find.byType(CropView), const Offset(-100, 0));
    await tester.pump();
    expect(view.controller.value.left, greaterThan(before.left));
  });
}
