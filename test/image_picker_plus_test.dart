import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/files/files_flow.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/image_picker_plus.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import 'fakes/fake_files_service.dart';
import 'fakes/pump_picker.dart';

void main() {
  late Fakes fakes;
  setUp(() {
    fakes = Fakes(files: FakeFilesService(next: FakeFilesService.files(2)));
    ImagePickerPlus.debugServices = fakes.services;
  });
  tearDown(() => ImagePickerPlus.debugServices = null);

  Future<Future<List<PickedItem>?>> open(
    WidgetTester tester, {
    PickerSettings settings = const PickerSettings(),
  }) async {
    late Future<List<PickedItem>?> result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = ImagePickerPlus.pick(context, settings: settings),
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

  testWidgets("desktop opens the system picker right away", (tester) async {
    await open(tester, settings: const PickerSettings(maxSelection: 3, mediaType: MediaType.all));
    expect(fakes.files.opens, 1);
    expect(fakes.files.lastMulti, isTrue);
    expect(fakes.files.lastType, MediaType.all);
    expect(find.byType(GalleryPage), findsNothing);
  }, variant: const TargetPlatformVariant({TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows}));

  testWidgets("single selection opens a single file picker", (tester) async {
    await open(tester);
    expect(fakes.files.lastMulti, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("cancel returns null and pushes nothing", (tester) async {
    fakes.files.next = [];
    final result = await open(tester, settings: const PickerSettings(filters: true));
    expect(find.byType(FilesFlow), findsNothing);
    expect(await result, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("with editing, the picked files open in the edit flow", (tester) async {
    final result = await open(tester, settings: const PickerSettings(maxSelection: 5, filters: true));
    expect(find.byType(FilesFlow), findsOneWidget);
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(await result, hasLength(2));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets("without editing, the picked files come back right away", (tester) async {
    final result = await open(tester, settings: const PickerSettings(maxSelection: 5));
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
    await open(tester, settings: const PickerSettings(source: PickerSource.both));
    expect(fakes.files.opens, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("a second pick while the system picker is open returns null", (tester) async {
    final pending = fakes.files.pending = Completer();
    final first = await open(tester);
    await tester.tap(find.text("open"));
    await tester.pump();
    expect(fakes.files.opens, 1);
    pending.complete([]);
    expect(await first, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("android opens the gallery", (tester) async {
    final result = await open(tester);
    expect(find.byType(GalleryPage), findsOneWidget);
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    expect((await result)!.single.file.path, "/fake/0");
    expect(fakes.files.opens, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
