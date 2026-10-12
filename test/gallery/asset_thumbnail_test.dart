import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/models/media_item.dart';

import '../fakes/fake_gallery_service.dart';

void main() {
  final item = fakeItem("7");

  test("same item, modified time and size are the same image", () {
    final gallery = FakeGalleryService();
    expect(AssetThumbnail(item, 100, gallery: gallery), AssetThumbnail(fakeItem("7"), 100, gallery: gallery));
    expect(
      AssetThumbnail(item, 100, gallery: gallery) == AssetThumbnail(item, 200, gallery: gallery),
      isFalse,
    );
  });

  testWidgets("a smaller tile reuses the smallest thumbnail already loaded for that item", (tester) async {
    imageCache
      ..clear()
      ..clearLiveImages();
    late _SlowGallery gallery;
    await tester.runAsync(() async {
      gallery = _SlowGallery()..gate.complete();
      for (final size in [300, 1000]) {
        final completer = Completer<void>();
        AssetThumbnail(
          item,
          size,
          gallery: gallery,
        ).resolve(ImageConfiguration.empty).addListener(ImageStreamListener((_, _) => completer.complete()));
        await completer.future;
      }
    });
    expect(mediaImage(item, 200, gallery: gallery), AssetThumbnail(item, 300, gallery: gallery));
    expect(mediaImage(item, 500, gallery: gallery), AssetThumbnail(item, 1000, gallery: gallery));
    expect(mediaImage(item, 2000, gallery: gallery), AssetThumbnail(item, 2000, gallery: gallery));
    expect(
      mediaImage(fakeItem("8"), 200, gallery: gallery),
      AssetThumbnail(fakeItem("8"), 200, gallery: gallery),
    );
    evictMediaImages();
  });

  testWidgets("evicting drops every loaded thumbnail from the image cache", (tester) async {
    late AssetThumbnail provider;
    await tester.runAsync(() {
      provider = AssetThumbnail(item, 30, gallery: _SlowGallery()..gate.complete());
      final completer = Completer<void>();
      provider
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (_, _) => completer.complete(),
              onError: (error, _) => completer.completeError(error),
            ),
          );
      return completer.future;
    });
    expect(imageCache.containsKey(provider), isTrue);
    evictMediaImages();
    await tester.pump();
    expect(imageCache.containsKey(provider), isFalse);
  });

  testWidgets("freeing for an export gives the cache back and keeps the shown image", (tester) async {
    imageCache
      ..clear()
      ..clearLiveImages();
    late AssetThumbnail provider;
    await tester.runAsync(() {
      provider = AssetThumbnail(item, 50, gallery: _SlowGallery()..gate.complete());
      final completer = Completer<void>();
      // the listener stays, like a cell still on screen behind the exporting popup
      provider
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (_, _) => completer.complete(),
              onError: (error, _) => completer.completeError(error),
            ),
          );
      return completer.future;
    });
    expect(imageCache.containsKey(provider), isTrue);
    await freeMediaImages();
    await tester.pump();
    expect(imageCache.containsKey(provider), isFalse);
    expect(imageCache.liveImageCount, 1);
  });

  testWidgets("a stream dropped while its thumbnail loads lets the image go when it lands", (tester) async {
    late _SlowGallery gallery;
    final errors = <Object>[];
    await tester.runAsync(() async {
      // made here, a completer from the fake async zone would never complete in real time
      gallery = _SlowGallery();
      final provider = AssetThumbnail(item, 40, gallery: gallery);
      runZonedGuarded(() {
        // ignore: invalid_use_of_protected_member
        final completer = provider.loadImage(
          provider,
          PaintingBinding.instance.instantiateImageCodecWithSize,
        );
        final listener = ImageStreamListener((_, _) {});
        // the cell scrolls away once the cache let go of it, after the picker closed or a memory clear
        completer
          ..addListener(listener)
          ..removeListener(listener);
      }, (error, _) => errors.add(error));
      gallery.gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    expect(gallery.loaded, isTrue);
    expect(errors, isEmpty);
  });
}

/// holds the thumbnail back until [gate] completes.
class _SlowGallery extends FakeGalleryService {
  final Completer<void> gate = Completer<void>();
  bool loaded = false;

  @override
  Future<Uint8List?> thumbnail(MediaItem item, int size) async {
    await gate.future;
    loaded = true;
    return img.encodePng(img.Image(width: 8, height: 8));
  }
}
