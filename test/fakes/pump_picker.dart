import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';

import 'fake_cache_service.dart';
import 'fake_camera_service.dart';
import 'fake_files_service.dart';
import 'fake_gallery_service.dart';
import 'fake_image_service.dart';

class Fakes {
  final FakeGalleryService gallery;
  final FakeCameraService camera;
  final FakeImageService image;
  final FakeFilesService files;
  final FakeCacheService? cache;

  Fakes({
    FakeGalleryService? gallery,
    FakeCameraService? camera,
    FakeImageService? image,
    FakeFilesService? files,
    this.cache,
  }) : gallery = gallery ?? FakeGalleryService(),
       camera = camera ?? FakeCameraService(),
       image = image ?? FakeImageService(),
       files = files ?? FakeFilesService();

  PickerServices get services =>
      PickerServices(gallery: gallery, camera: () => camera, image: image, files: files, cache: cache);
}

/// pumps [child] inside a route of a [MaterialApp], with a [PickerScope] of fakes.
/// the route result goes to [onResult].
Future<void> pumpPicker(
  WidgetTester tester,
  Widget child, {
  Fakes? fakes,
  PickerSettings settings = const PickerSettings(),
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  Size size = const Size(400, 800),
  // loading boxes animate forever, which pumpAndSettle never gets past
  bool disableAnimations = true,
  double textScale = 1,
  void Function(Object? result)? onResult,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final services = (fakes ?? Fakes()).services;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: disableAnimations,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, app) => Directionality(textDirection: direction, child: app!),
        home: _Opener(
          onResult: onResult,
          page: PickerScope(
            settings: settings,
            theme: PickerTheme.resolve(
              settings.theme,
              settings.alwaysDarkTheme ? Brightness.dark : brightness,
            ),
            services: services,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_Opener.openKey));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

class _Opener extends StatelessWidget {
  static const openKey = Key("open-picker");
  final Widget page;
  final void Function(Object? result)? onResult;

  const _Opener({required this.page, this.onResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: openKey,
          onPressed: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute<Object?>(builder: (_) => page));
            onResult?.call(result);
          },
          child: const Text("open"),
        ),
      ),
    );
  }
}
