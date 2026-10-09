import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';

import '../fakes/fake_cache_service.dart';
import '../fakes/fake_gallery_service.dart';

void main() {
  final item = fakeItem("7");

  test("cache hit doesn't ask the gallery", () async {
    final gallery = FakeGalleryService();
    final cache = FakeCacheService();
    final provider = AssetThumbnail(item, 100, gallery: gallery, cache: cache);
    cache.data[provider.cacheKey] = tinyPng;
    expect(await provider.loadBytes(), tinyPng);
    expect(gallery.thumbnailCalls, 0);
    expect(cache.reads, 1);
  });

  test("cache miss asks the gallery and writes", () async {
    final gallery = FakeGalleryService();
    final cache = FakeCacheService();
    await AssetThumbnail(item, 101, gallery: gallery, cache: cache).loadBytes();
    expect(gallery.thumbnailCalls, 1);
    expect(cache.writes, 1);
    expect(cache.data.keys.single, "thumb:7:${item.modified.millisecondsSinceEpoch}:101");
  });

  test("no cache when it's off", () async {
    final gallery = FakeGalleryService();
    await AssetThumbnail(item, 102, gallery: gallery).loadBytes();
    expect(gallery.thumbnailCalls, 1);
  });

  test("same item, modified time and size are the same image", () {
    final gallery = FakeGalleryService();
    expect(AssetThumbnail(item, 100, gallery: gallery), AssetThumbnail(fakeItem("7"), 100, gallery: gallery));
    expect(
      AssetThumbnail(item, 100, gallery: gallery) == AssetThumbnail(item, 200, gallery: gallery),
      isFalse,
    );
    expect(
      AssetThumbnail(item, 100, gallery: gallery) ==
          AssetThumbnail(item, 100, gallery: gallery, cover: const Size(100, 100)),
      isFalse,
    );
  });

  testWidgets("cover cuts a wide thumbnail to the cell", (tester) async {
    final cache = FakeCacheService();
    final provider = AssetThumbnail(
      item,
      20,
      gallery: FakeGalleryService(),
      cache: cache,
      cover: const Size(20, 20),
    );
    cache.data[provider.cacheKey] = img.encodePng(img.Image(width: 50, height: 20));
    final info = await tester.runAsync(() {
      final completer = Completer<ImageInfo>();
      provider
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((info, _) => completer.complete(info)));
      return completer.future;
    });
    expect([info!.image.width, info.image.height], [20, 20]);
  });
}
