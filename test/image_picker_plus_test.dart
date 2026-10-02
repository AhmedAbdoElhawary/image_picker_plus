import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/image_picker_plus.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';

import 'fakes/pump_picker.dart';

void main() {
  setUp(() => ImagePickerPlus.debugServices = Fakes().services);
  tearDown(() => ImagePickerPlus.debugServices = null);

  Future<Future<List<PickedItem>?>> open(WidgetTester tester) async {
    late Future<List<PickedItem>?> result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = ImagePickerPlus.pick(context),
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

  testWidgets("unsupported platform shows the message and close returns null", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final result = await open(tester);
    expect(find.text("This platform is not supported yet"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(await result, isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets("android opens the gallery", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final result = await open(tester);
    expect(find.byType(GalleryPage), findsOneWidget);
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    expect((await result)!.single.file.path, "/fake/0");
    debugDefaultTargetPlatformOverride = null;
  });
}
