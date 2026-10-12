import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/files/files_flow.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/image_picker_plus.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';

import 'fakes/fake_files_service.dart';
import 'fakes/pump_picker.dart';

void main() {
  const noEdit = PickerSettings(cropRatios: []);
  late Fakes fakes;
  setUp(() {
    fakes = Fakes(files: FakeFilesService(next: FakeFilesService.files(2)));
    ImagePickerPlus.debugServices = fakes.services;
  });
  tearDown(() => ImagePickerPlus.debugServices = null);

  Future<Future<List<PickedItem>?>> open(
    WidgetTester tester, {
    PickerSettings settings = const PickerSettings(),
    List<PickedItem>? selected,
  }) async {
    late Future<List<PickedItem>?> result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = ImagePickerPlus.pick(context, settings: settings, selected: selected),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets(
    "desktop opens the system picker right away",
    (tester) async {
      await open(
        tester,
        settings: const PickerSettings(maxSelection: 3, mediaType: MediaType.all, cropRatios: []),
      );
      expect(fakes.files.opens, 1);
      expect(fakes.files.lastMulti, isTrue);
      expect(fakes.files.lastType, MediaType.all);
      expect(find.byType(GalleryPage), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets("single selection opens a single file picker", (tester) async {
    await open(tester, settings: noEdit);
    expect(fakes.files.lastMulti, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("cancel returns null and pushes nothing", (tester) async {
    fakes.files.next = [];
    final result = await open(tester, settings: const PickerSettings(filters: PickerFilter.all));
    expect(find.byType(FilesFlow), findsNothing);
    expect(await result, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("with editing, the picked files open in the edit flow", (tester) async {
    final result = await open(
      tester,
      settings: const PickerSettings(maxSelection: 5, filters: PickerFilter.all),
    );
    expect(find.byType(FilesFlow), findsOneWidget);
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(await result, hasLength(2));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets("without editing, the picked files come back right away", (tester) async {
    final result = await open(tester, settings: const PickerSettings(maxSelection: 5, cropRatios: []));
    expect(find.byType(FilesFlow), findsNothing);
    final items = (await result)!;
    expect(items.map((item) => item.file.path), ["/picked/0.jpg", "/picked/1.jpg"]);
    expect(items.every((item) => !item.edited), isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("camera only shows not supported and close returns null", (tester) async {
    final result = await open(tester, settings: const PickerSettings(source: PickerSource.camera));
    expect(find.text("This platform is not supported yet"), findsOneWidget);
    expect(fakes.files.opens, 0);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("gallery and camera works like gallery only", (tester) async {
    await open(
      tester,
      settings: const PickerSettings(source: PickerSource.both, cropRatios: []),
    );
    expect(fakes.files.opens, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("a second pick while the system picker is open returns null", (tester) async {
    final pending = fakes.files.pending = Completer();
    final first = await open(tester, settings: noEdit);
    await tester.tap(find.text("open"));
    await tester.pump();
    expect(fakes.files.opens, 1);
    pending.complete([]);
    expect(await first, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("android opens the gallery", (tester) async {
    final result = await open(tester, settings: noEdit);
    expect(find.byType(GalleryPage), findsOneWidget);
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    expect((await result)!.single.file.path, "/fake/0");
    expect(fakes.files.opens, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets("dark in a light app by default, alwaysDarkTheme false follows the app", (tester) async {
    Color? background() => tester
        .widget<Scaffold>(find.descendant(of: find.byType(GalleryPage), matching: find.byType(Scaffold)))
        .backgroundColor;
    await open(tester);
    expect(background(), PickerTheme.dark().background);

    await tester.pumpWidget(const SizedBox());
    await open(tester, settings: const PickerSettings(alwaysDarkTheme: false));
    expect(background(), PickerTheme.light().background);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  group("selected", () {
    PickedItem picked(String id) => PickedItem(
      file: XFile("/fake/$id"),
      type: MediaType.image,
      width: 400,
      height: 300,
      edited: false,
      id: id,
    );
    const multi = PickerSettings(maxSelection: 5, cropRatios: []);

    testWidgets("opens with an earlier pick and done gives it back in order", (tester) async {
      final result = await open(tester, settings: multi, selected: [picked("3"), picked("1"), picked("7")]);
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect((await result)!.map((e) => e.id), ["3", "1", "7"]);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    group("with editing", () {
      const editing = PickerSettings(maxSelection: 5, filters: PickerFilter.all);

      testWidgets("opens the edit page right away and back closes the picker", (tester) async {
        final result = await open(tester, settings: editing, selected: [picked("3"), picked("1")]);
        expect(find.byType(EditPage), findsOneWidget);
        expect(find.byType(GalleryPage, skipOffstage: false), findsOneWidget);
        expect(find.byType(GalleryPage), findsNothing);
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(GalleryPage, skipOffstage: false), findsNothing);
        expect(await result, isNull);
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));

      testWidgets("the plus shows the gallery, and back on the edit page after adding still closes", (
        tester,
      ) async {
        final result = await open(tester, settings: editing, selected: [picked("3")]);
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(EditPage), findsNothing);
        expect(find.byType(GalleryPage), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey("0")));
        await tester.pump();
        await tester.tap(find.text("Add"));
        await tester.pumpAndSettle();
        expect(tester.widget<EditPage>(find.byType(EditPage)).items.map((e) => e.id), ["3", "0"]);
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        expect(await result, isNull);
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));

      testWidgets("all of them gone opens the gallery", (tester) async {
        fakes.gallery.gone.addAll(["3", "1"]);
        await open(tester, settings: editing, selected: [picked("3"), picked("1")]);
        expect(find.byType(EditPage), findsNothing);
        expect(find.byType(GalleryPage), findsOneWidget);
        expect(find.text("Some files couldn't be opened"), findsOneWidget);
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));
    });

    testWidgets("a gone item shows the skipped message once", (tester) async {
      fakes.gallery.gone.add("1");
      await open(tester, settings: multi, selected: [picked("3"), picked("1")]);
      expect(find.text("Some files couldn't be opened"), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets("desktop skips the system picker and opens the edit page with them", (tester) async {
      final files = [
        for (final path in ["/picked/a.jpg", "/picked/b.jpg"])
          PickedItem(file: XFile(path), type: MediaType.image, width: 400, height: 300, edited: false),
      ];
      final result = await open(tester, settings: multi, selected: files);
      expect(fakes.files.opens, 0);
      expect(find.byType(FilesFlow), findsOneWidget);
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect((await result)!.map((e) => e.file.path), ["/picked/a.jpg", "/picked/b.jpg"]);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets("edits come back, also through a json round trip", (tester) async {
      const settings = PickerSettings(maxSelection: 5, filters: PickerFilter.all);
      const edit = EditState(
        cropRect: Rect.fromLTWH(0.1, 0, 0.75, 1),
        ratio: CropRatio.square,
        filterIndex: 3,
      );
      final first = PickedItem(
        file: XFile("/fake/2.edited.jpg"),
        type: MediaType.image,
        width: 300,
        height: 300,
        edited: true,
        id: "2",
        original: XFile("/fake/2"),
        edit: edit,
      );
      final saved = PickedItem.fromMap(
        (jsonDecode(jsonEncode(first.toMap())) as Map).cast<String, Object?>(),
      );
      final result = await open(tester, settings: settings, selected: [saved]);
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect(fakes.image.calls.single.$2, edit);
      expect((await result)!.single.edit, edit);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
