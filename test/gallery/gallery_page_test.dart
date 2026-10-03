import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/capture_button.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/gallery/gallery_cell.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';
import 'package:image_picker_plus/src/gallery/ratio_button.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';

import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  Finder cell(String id) => find.byKey(ValueKey(id));

  testWidgets("the grid shows the items", (tester) async {
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: FakeGalleryService.withItems(30)));
    expect(find.byType(GalleryCell), findsWidgets);
    expect(cell("0"), findsOneWidget);
  });

  double badgeOpacity(WidgetTester tester, String order) => tester
      .widget<AnimatedOpacity>(find.ancestor(of: find.text(order), matching: find.byType(AnimatedOpacity)).first)
      .opacity;

  testWidgets("a long press starts counting with a vibration, and past the max shows the message", (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
      settings: const PickerSettings(maxSelection: 2),
    );
    expect(badgeOpacity(tester, "1"), 0);
    expect(find.text("Select"), findsOneWidget);

    await tester.longPress(cell("1"));
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == "HapticFeedback.vibrate"), hasLength(1));
    expect(find.text("Cancel"), findsOneWidget);
    expect(find.descendant(of: cell("1"), matching: find.text("1")), findsOneWidget);
    expect(badgeOpacity(tester, "1"), 1);

    await tester.tap(cell("2"));
    await tester.pumpAndSettle();
    expect(find.descendant(of: cell("2"), matching: find.text("2")), findsOneWidget);

    await tester.tap(cell("3"));
    await tester.pump();
    expect(find.text("You can select up to 2 items"), findsOneWidget);
  });

  testWidgets("select counts from the shown item and cancel keeps only the shown one", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
      settings: const PickerSettings(maxSelection: 3, cropRatios: []),
      onResult: (r) => result = r,
    );
    await tester.tap(find.text("Select"));
    await tester.pumpAndSettle();
    expect(find.descendant(of: cell("0"), matching: find.text("1")), findsOneWidget);
    await tester.tap(cell("4"));
    await tester.pumpAndSettle();
    expect(find.descendant(of: cell("4"), matching: find.text("2")), findsOneWidget);

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(find.text("Select"), findsOneWidget);
    expect(badgeOpacity(tester, "1"), 0);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    expect((result! as List<PickedItem>).map((e) => e.file.path), ["/fake/4"]);
  });

  group("adding from the edit page", () {
    const editing = PickerSettings(maxSelection: 3, filters: true);

    Future<void> openEdit(WidgetTester tester, {void Function(Object?)? onResult}) async {
      await pumpPicker(
        tester,
        const PickerHome(),
        fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
        settings: editing,
        onResult: onResult,
      );
      await tester.tap(find.text("Select"));
      await tester.pump();
      await tester.tap(cell("4"));
      await tester.pump();
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
    }

    testWidgets("the plus goes back to count more, add puts them last and shows the first new one", (tester) async {
      Object? result;
      await openEdit(tester, onResult: (r) => result = r);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(EditPage), findsNothing);
      expect(find.text("Add"), findsOneWidget);
      expect(find.text("Cancel"), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(cell("7"));
      await tester.pump();
      await tester.tap(cell("8"));
      await tester.pump();
      expect(find.text("You can select up to 3 items"), findsOneWidget);

      await tester.tap(find.text("Add"));
      await tester.pumpAndSettle();
      final edit = find.byType(EditPage);
      expect(tester.widget<EditPage>(edit).initial?.id, "7");
      // at the max there's no plus
      expect(find.byIcon(Icons.add_rounded), findsNothing);

      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect((result! as List<PickedItem>).map((e) => e.file.path), ["/fake/0", "/fake/4", "/fake/7"]);
    });

    testWidgets("back while adding drops the new ones and opens the edit page again", (tester) async {
      Object? result;
      await openEdit(tester, onResult: (r) => result = r);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(cell("7"));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(EditPage), findsOneWidget);

      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect((result! as List<PickedItem>).map((e) => e.file.path), ["/fake/0", "/fake/4"]);
    });
  });

  group("adding from the camera", () {
    const both = PickerSettings(source: PickerSource.both, maxSelection: 3, filters: true);

    Future<void> openEdit(WidgetTester tester, {void Function(Object?)? onResult}) async {
      await pumpPicker(
        tester,
        const PickerHome(),
        fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
        settings: both,
        onResult: onResult,
      );
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      // one item, but there's room, so the plus is there
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
    }

    testWidgets("a tap counts after a single selection, and a photo goes after them", (tester) async {
      Object? result;
      await openEdit(tester, onResult: (r) => result = r);
      await tester.tap(cell("5"));
      await tester.pump();
      expect(find.descendant(of: cell("5"), matching: find.text("2")), findsOneWidget);

      await tester.tap(find.text("Photo"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CaptureButton));
      await tester.pumpAndSettle();
      // the first new one
      expect(tester.widget<EditPage>(find.byType(EditPage)).initial?.id, "5");

      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect((result! as List<PickedItem>).map((e) => e.file.path), ["/fake/0", "/fake/5", "/fake/photo.jpg"]);
    });

    testWidgets("back on the camera while adding opens the edit page again", (tester) async {
      Object? result;
      await openEdit(tester, onResult: (r) => result = r);
      await tester.tap(find.text("Photo"));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(EditPage), findsOneWidget);

      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect((result! as List<PickedItem>).map((e) => e.file.path), ["/fake/0"]);
    });
  });

  testWidgets("a max of 1 has no select button and a long press does nothing", (tester) async {
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: FakeGalleryService.withItems(30)));
    expect(find.text("Select"), findsNothing);
    await tester.longPress(cell("3"));
    await tester.pumpAndSettle();
    expect(find.text("1"), findsNothing);
  });

  testWidgets("without the preview the select button sits over the grid", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
      settings: const PickerSettings(maxSelection: 3, showPreview: false),
    );
    expect(find.byType(MediaPreview), findsNothing);
    await tester.tap(find.text("Select"));
    await tester.pumpAndSettle();
    expect(find.text("Cancel"), findsOneWidget);
  });

  testWidgets("scrolling shows the date beside the scrollbar, then hides it", (tester) async {
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: FakeGalleryService.withItems(200)));
    double opacity() => tester
        .widget<AnimatedOpacity>(find.ancestor(of: find.text("January 2026"), matching: find.byType(AnimatedOpacity)))
        .opacity;

    await tester.drag(find.byType(GridView), const Offset(0, -300));
    await tester.pump();
    expect(opacity(), 1);

    await tester.pump(const Duration(seconds: 2));
    expect(opacity(), 0);
  });

  testWidgets("holding the scrollbar shrinks the date and moves it off the edge", (tester) async {
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: FakeGalleryService.withItems(200)));
    double held() =>
        tester.widget<TweenAnimationBuilder<double>>(find.byType(TweenAnimationBuilder<double>)).tween.end!;
    await tester.drag(find.byType(GridView), const Offset(0, -300));
    await tester.pump();
    expect(held(), 0);

    final gesture = await tester.startGesture(tester.getCenter(find.text("January 2026")));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(held(), 1);

    await gesture.up();
    await tester.pump();
    expect(held(), 0);
  });

  testWidgets("denied shows the message with open settings and close", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(5, access: GalleryAccess.denied));
    Object? result = "not closed";
    await pumpPicker(tester, const PickerHome(), fakes: fakes, onResult: (r) => result = r);
    expect(find.byType(MessageView), findsOneWidget);
    expect(find.text("Allow access to your photos to continue"), findsOneWidget);

    await tester.tap(find.text("Open settings"));
    expect(fakes.gallery.openSettingsCalls, 1);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets("empty shows no images with close", (tester) async {
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: FakeGalleryService.withItems(0)));
    expect(find.text("There are no images"), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets("limited shows manage access", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(5, access: GalleryAccess.limited));
    await pumpPicker(tester, const PickerHome(), fakes: fakes);
    await tester.tap(find.text("Manage access"));
    await tester.pumpAndSettle();
    expect(fakes.gallery.manageCalls, 1);
  });

  testWidgets("next pops the picked items in order", (tester) async {
    Object? result;
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: Fakes(gallery: FakeGalleryService.withItems(30)),
      settings: const PickerSettings(maxSelection: 3, cropRatios: []),
      onResult: (r) => result = r,
    );
    await tester.tap(find.text("Select"));
    await tester.pump();
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
    await pumpPicker(tester, const PickerHome(), onResult: (r) => result = r);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets("the rest of the album loads without scrolling", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(200));
    await pumpPicker(tester, const PickerHome(), fakes: fakes);
    // 10 full pages, the 11th comes back empty and ends it
    expect(fakes.gallery.pageCalls.length, 11);
  });

  testWidgets("switching album from the sheet", (tester) async {
    final gallery = FakeGalleryService(
      data: {"all": List.generate(10, (i) => fakeItem("a$i")), "Camera": List.generate(3, (i) => fakeItem("b$i"))},
    );
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: gallery));
    expect(find.text("Recent"), findsOneWidget);
    await tester.tap(find.text("Recent"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Camera"));
    await tester.pumpAndSettle();
    expect(cell("b0"), findsOneWidget);
    expect(cell("a1"), findsNothing);
  });

  testWidgets("switching album goes back to the top with the preview fully shown", (tester) async {
    final gallery = FakeGalleryService(
      data: {"all": List.generate(200, (i) => fakeItem("a$i")), "Camera": List.generate(100, (i) => fakeItem("b$i"))},
    );
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: gallery));
    final top = tester.getTopLeft(find.byType(MediaPreview)).dy;
    await tester.drag(find.byType(GridView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MediaPreview)).dy, lessThan(top));

    await tester.tap(find.text("Recent"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Camera"));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MediaPreview)).dy, top);
    expect(tester.widget<GridView>(find.byType(GridView)).controller!.offset, 0);
    expect(find.descendant(of: find.byType(MediaPreview), matching: find.byType(PreviewImage)), findsOneWidget);
  });

  testWidgets("crop in the preview, then next opens the edit page and done returns the crop", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(10));
    Object? result;
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: fakes,
      settings: const PickerSettings(cropRatios: [CropRatio.square, CropRatio.portrait]),
      onResult: (r) => result = r,
    );
    expect(find.byType(CropView), findsOneWidget);
    expect(find.text("1:1"), findsOneWidget);
    await tester.tap(find.text("1:1"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("4:5"));
    await tester.pumpAndSettle();
    // the menu closed and the button shows the pick
    expect(find.text("1:1"), findsNothing);
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
      const PickerHome(),
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

  testWidgets("the preview is decoded at the size it's shown, also while zoomed", (tester) async {
    int previewSize() =>
        (tester.widget<Image>(find.descendant(of: find.byType(PreviewImage), matching: find.byType(Image))).image
                as AssetThumbnail)
            .size;
    await pumpPicker(tester, const PickerHome(), settings: const PickerSettings(cropRatios: [CropRatio.square]));
    // a 4:3 image covering the square window, its short side is the window side
    final box = tester.getSize(find.byType(CropView));
    final side = min(box.width, box.height).round();
    expect(previewSize(), side);

    tester.widget<CropView>(find.byType(CropView)).controller.zoomTo(3);
    await tester.pump();
    expect(previewSize(), side);
  });

  testWidgets("resizePreview off decodes the preview at 1080", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(cropRatios: [CropRatio.square], resizePreview: false),
    );
    final image = tester.widget<Image>(find.descendant(of: find.byType(PreviewImage), matching: find.byType(Image)));
    expect((image.image as AssetThumbnail).size, MediaPreview.imageSize);
  });

  testWidgets("dragging the crop moves it", (tester) async {
    await pumpPicker(tester, const PickerHome(), settings: const PickerSettings(cropRatios: [CropRatio.square]));
    final view = tester.widget<CropView>(find.byType(CropView));
    final before = view.controller.value;
    await tester.drag(find.byType(CropView), const Offset(-100, 0));
    await tester.pump();
    expect(view.controller.value.left, greaterThan(before.left));
  });

  testWidgets("a tap outside the ratio menu closes it and keeps the ratio", (tester) async {
    await pumpPicker(
      tester,
      const PickerHome(),
      settings: const PickerSettings(cropRatios: [CropRatio.square, CropRatio.portrait]),
    );
    await tester.tap(find.text("1:1"));
    await tester.pumpAndSettle();
    expect(find.text("4:5"), findsOneWidget);
    await tester.tapAt(const Offset(200, 700));
    await tester.pumpAndSettle();
    expect(find.text("4:5"), findsNothing);
    expect(find.text("1:1"), findsOneWidget);
  });

  testWidgets("no preview: no crop view, and the edit page crops at the image's own ratio", (tester) async {
    final fakes = Fakes(gallery: FakeGalleryService.withItems(10));
    await pumpPicker(
      tester,
      const PickerHome(),
      fakes: fakes,
      settings: const PickerSettings(showPreview: false, cropRatios: [CropRatio.square]),
    );
    expect(find.byType(MediaPreview), findsNothing);
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    final crop = tester.widget<CropView>(find.byType(CropView)).controller;
    expect(crop.ratio, CropRatio.original);
    expect(find.byType(RatioButton), findsNothing);
  });

  testWidgets("scrolling the grid slides the preview up to a strip, and a tap on it brings it back", (tester) async {
    await pumpPicker(tester, const PickerHome(), fakes: Fakes(gallery: FakeGalleryService.withItems(80)));
    final top = tester.getTopLeft(find.byType(MediaPreview)).dy;
    await tester.drag(find.byType(GridView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final strip = tester.getBottomLeft(find.byType(MediaPreview)).dy;
    expect(tester.getTopLeft(find.byType(MediaPreview)).dy, lessThan(top));
    expect(strip - top, closeTo(48, 0.5));
    await tester.tapAt(Offset(200, strip - 10));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MediaPreview)).dy, top);
  });
}
