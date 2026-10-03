import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker_plus/src/services/cache_service.dart';

/// files on disk, the modified time is the last read, so the oldest go first.
class CacheServiceImpl implements CacheService {
  final Directory root;
  final int maxBytes;

  // listing the folder on every write is slow, so the total is kept after one scan
  int? _total;

  CacheServiceImpl({Directory? root, required this.maxBytes}) : root = root ?? defaultRoot;

  static Directory get defaultRoot => Directory("${Directory.systemTemp.path}/image_picker_plus_cache");

  // the key itself, so two keys never share a file
  File _file(String key) => File("${root.path}/${Uri.encodeComponent(key)}");

  @override
  Future<Uint8List?> read(String key) async {
    final file = _file(key);
    try {
      final bytes = await file.readAsBytes();
      await file.setLastModified(DateTime.now());
      return bytes;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    try {
      await root.create(recursive: true);
      final file = _file(key);
      final old = await file.exists() ? await file.length() : 0;
      await file.writeAsBytes(bytes, flush: true);
      _total = (_total ?? await _scan()) - old + bytes.length;
      if (_total! > maxBytes) await _evict();
    } on FileSystemException {
      // a full disk only means no cache, the picker still works
    }
  }

  @override
  Future<void> clear() async {
    _total = null;
    if (await root.exists()) await root.delete(recursive: true);
  }

  Future<int> _scan() async {
    var total = 0;
    await for (final entity in root.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> _evict() async {
    final files = <(File, DateTime, int)>[];
    await for (final entity in root.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        files.add((entity, stat.modified, stat.size));
      }
    }
    files.sort((a, b) => a.$2.compareTo(b.$2));
    var total = files.fold<int>(0, (sum, f) => sum + f.$3);
    for (final (file, _, size) in files) {
      if (total <= maxBytes) break;
      await file.delete();
      total -= size;
    }
    _total = total;
  }
}
