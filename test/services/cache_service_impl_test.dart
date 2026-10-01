import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/services/cache_service_impl.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory("${Directory.systemTemp.createTempSync("cache_test").path}/cache"));
  tearDown(() => root.parent.deleteSync(recursive: true));

  Uint8List bytes(int length, [int value = 1]) => Uint8List(length)..fillRange(0, length, value);

  test("write then read returns the bytes, a missing key is null", () async {
    final cache = CacheServiceImpl(root: root, maxBytes: 1000);
    await cache.write("thumb:a/b:1:200", bytes(10, 7));
    expect(await cache.read("thumb:a/b:1:200"), bytes(10, 7));
    expect(await cache.read("missing"), isNull);
  });

  test("keys that look alike never share a file", () async {
    final cache = CacheServiceImpl(root: root, maxBytes: 1000);
    await cache.write("a:b", bytes(5, 1));
    await cache.write("a_b", bytes(5, 2));
    await cache.write("a/b", bytes(5, 3));
    expect((await cache.read("a:b"))!.first, 1);
    expect((await cache.read("a_b"))!.first, 2);
    expect((await cache.read("a/b"))!.first, 3);
  });

  test("read moves the modified time to now", () async {
    final cache = CacheServiceImpl(root: root, maxBytes: 1000);
    await cache.write("k", bytes(10));
    final file = root.listSync().whereType<File>().single;
    final old = DateTime.now().subtract(const Duration(days: 3));
    file.setLastModifiedSync(old);
    await cache.read("k");
    expect(file.lastModifiedSync().isAfter(old.add(const Duration(days: 1))), isTrue);
  });

  test("going over the limit deletes the oldest first", () async {
    final cache = CacheServiceImpl(root: root, maxBytes: 250);
    await cache.write("a", bytes(100));
    await cache.write("b", bytes(100));
    final now = DateTime.now();
    for (final file in root.listSync().whereType<File>()) {
      final name = Uri.decodeComponent(file.uri.pathSegments.last);
      file.setLastModifiedSync(now.subtract(Duration(hours: name == "a" ? 2 : 1)));
    }
    await cache.write("c", bytes(100));
    expect(await cache.read("a"), isNull);
    expect(await cache.read("b"), isNotNull);
    expect(await cache.read("c"), isNotNull);
    final total = root.listSync().whereType<File>().fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(total, lessThanOrEqualTo(250));
  });

  test("an existing folder counts toward the limit", () async {
    await CacheServiceImpl(root: root, maxBytes: 1000).write("old", bytes(200));
    final cache = CacheServiceImpl(root: root, maxBytes: 250);
    await cache.write("new", bytes(100));
    final total = root.listSync().whereType<File>().fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(total, lessThanOrEqualTo(250));
  });

  test("clear removes the folder", () async {
    final cache = CacheServiceImpl(root: root, maxBytes: 1000);
    await cache.write("k", bytes(10));
    await cache.clear();
    expect(root.existsSync(), isFalse);
    await cache.clear();
  });

  test("the default folder is in the temp folder", () {
    expect(CacheServiceImpl.defaultRoot.path, endsWith("image_picker_plus_cache"));
  });
}
