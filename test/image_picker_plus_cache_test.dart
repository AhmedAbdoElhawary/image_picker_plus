import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/image_picker_plus.dart';
import 'package:image_picker_plus/src/services/cache_service_impl.dart';
import 'package:image_picker_plus/src/settings/picker_cache.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import 'fakes/pump_picker.dart';

void main() {
  final root = CacheServiceImpl.defaultRoot;

  setUp(() => ImagePickerPlus.debugServices = Fakes().services);
  tearDown(() {
    ImagePickerPlus.debugServices = null;
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  void fillCache() {
    root.createSync(recursive: true);
    File("${root.path}/old").writeAsBytesSync([1, 2, 3]);
  }

  Future<void> open(WidgetTester tester, PickerSettings settings) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => ImagePickerPlus.pick(context, settings: settings),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets("cache off removes an old cache folder on open", (tester) async {
    fillCache();
    await open(tester, const PickerSettings());
    expect(root.existsSync(), isFalse);
  });

  testWidgets("cache on keeps it", (tester) async {
    fillCache();
    await open(tester, const PickerSettings(cache: PickerCache(enabled: true)));
    expect(root.existsSync(), isTrue);
  });

  test("clearCache empties it", () async {
    fillCache();
    await ImagePickerPlus.clearCache();
    expect(root.existsSync(), isFalse);
  });
}
