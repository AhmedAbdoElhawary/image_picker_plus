import 'package:flutter_test/flutter_test.dart';
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
  });
}
