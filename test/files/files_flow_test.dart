import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/files/files_flow.dart';
import 'package:image_picker_plus/src/gallery/ratio_button.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_files_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  const settings = PickerSettings(
    maxSelection: 5,
    cropRatios: [CropRatio.square, CropRatio.portrait],
    filters: true,
  );

  Future<Fakes> open(
    WidgetTester tester,
    List<XFile> files, {
    FakeFilesService? service,
    PickerSettings settings = settings,
    void Function(Object?)? onResult,
  }) async {
    final fakes = Fakes(files: service ?? FakeFilesService());
    await pumpPicker(
      tester,
      FilesFlow(files: files),
      fakes: fakes,
      settings: settings,
      onResult: onResult,
    );
    return fakes;
  }

  testWidgets("opens the edit page with the picked items, and done returns them", (tester) async {
    Object? result;
    final fakes = await open(tester, FakeFilesService.files(2), onResult: (r) => result = r);
    expect(find.byType(EditPage), findsOneWidget);
    expect(find.byType(RatioButton), findsOneWidget);
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    final items = result! as List<PickedItem>;
    expect(items, hasLength(2));
    expect(fakes.image.calls.map((call) => call.$1), ["/picked/0.jpg", "/picked/1.jpg"]);
  });

  testWidgets("an unedited picked image comes back as its own file", (tester) async {
    Object? result;
    await open(
      tester,
      FakeFilesService.files(1),
      settings: const PickerSettings(filters: true),
      onResult: (r) => result = r,
    );
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    final item = (result! as List<PickedItem>).single;
    expect(item.file.path, "/picked/0.jpg");
    expect(item.edited, isFalse);
  });

  testWidgets("back picks again and the new pick replaces the old one", (tester) async {
    Object? result;
    final service = FakeFilesService(next: [XFile("/picked/new.jpg", name: "new.jpg")]);
    final fakes = await open(
      tester,
      FakeFilesService.files(2),
      service: service,
      onResult: (r) => result = r,
    );
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(service.opens, 1);
    expect(service.lastMulti, isTrue);
    expect(find.byType(EditPage), findsOneWidget);
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(result, isA<List<PickedItem>>());
    expect(fakes.image.calls.map((call) => call.$1), ["/picked/new.jpg"]);
  });

  testWidgets("the plus adds files after the others, only as many as fit, and skips ones already there", (
    tester,
  ) async {
    Object? result;
    final service = FakeFilesService(
      next: [...FakeFilesService.files(1), ...FakeFilesService.files(6).skip(2)],
    );
    final fakes = await open(
      tester,
      FakeFilesService.files(2),
      service: service,
      onResult: (r) => result = r,
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(service.lastMulti, isTrue);
    expect(find.text("Only the first 5 were kept"), findsOneWidget);
    expect(tester.widget<EditPage>(find.byType(EditPage)).initial?.id, "/picked/2.jpg");
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(result, isA<List<PickedItem>>());
    expect(fakes.image.calls.map((call) => call.$1), [
      "/picked/0.jpg",
      "/picked/1.jpg",
      "/picked/2.jpg",
      "/picked/3.jpg",
      "/picked/4.jpg",
    ]);
  });

  testWidgets("back and cancel closes with null", (tester) async {
    Object? result = "not closed";
    await open(tester, FakeFilesService.files(2), onResult: (r) => result = r);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(FilesFlow), findsNothing);
    expect(result, isNull);
  });

  testWidgets("only the newest re-pick is used", (tester) async {
    Object? result;
    final service = FakeFilesService();
    final fakes = await open(
      tester,
      FakeFilesService.files(1),
      service: service,
      onResult: (r) => result = r,
    );
    final old = service.pending = Completer();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    service.next = [XFile("/picked/newest.jpg", name: "newest.jpg")];
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    old.complete([XFile("/picked/old.jpg", name: "old.jpg")]);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(result, isA<List<PickedItem>>());
    expect(fakes.image.calls.map((call) => call.$1), ["/picked/newest.jpg"]);
  });

  testWidgets("more than the max shows the kept message", (tester) async {
    await open(tester, FakeFilesService.files(7));
    expect(find.text("Only the first 5 were kept"), findsOneWidget);
  });

  testWidgets("unreadable files show the skipped message", (tester) async {
    await open(tester, FakeFilesService.files(2), service: FakeFilesService(unreadable: {"/picked/0.jpg"}));
    expect(find.text("Some files couldn't be opened"), findsOneWidget);
    expect(find.byType(EditPage), findsOneWidget);
  });

  testWidgets("nothing readable shows the message and closes with null", (tester) async {
    Object? result = "not closed";
    await open(
      tester,
      FakeFilesService.files(1),
      service: FakeFilesService(unreadable: {"/picked/0.jpg"}),
      onResult: (r) => result = r,
    );
    expect(find.text("Some files couldn't be opened"), findsOneWidget);
    expect(find.byType(FilesFlow), findsNothing);
    expect(result, isNull);
  });

  testWidgets("a picked video is reordered only and comes back as it is", (tester) async {
    Object? result;
    final files = [XFile("/picked/clip.mp4", name: "clip.mp4"), ...FakeFilesService.files(1)];
    final fakes = await open(
      tester,
      files,
      settings: const PickerSettings(maxSelection: 5, mediaType: MediaType.all, filters: true),
      onResult: (r) => result = r,
    );
    expect(find.text("Videos can only be reordered"), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsWidgets);
    final ignore = tester.widget<IgnorePointer>(
      find.ancestor(of: find.byType(ListView).first, matching: find.byType(IgnorePointer)).first,
    );
    expect(ignore.ignoring, isTrue);
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    final items = result! as List<PickedItem>;
    expect(items.first.file.path, "/picked/clip.mp4");
    expect(items.first.type, MediaType.video);
    expect(items.first.edited, isFalse);
    expect(items.first.width, 0);
    expect(fakes.image.calls, isEmpty);
  });
}
