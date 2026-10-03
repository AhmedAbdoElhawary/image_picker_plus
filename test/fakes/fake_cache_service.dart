import 'dart:typed_data';

import 'package:image_picker_plus/src/services/cache_service.dart';

class FakeCacheService implements CacheService {
  final Map<String, Uint8List> data = {};
  int reads = 0;
  int writes = 0;
  int clears = 0;

  @override
  Future<Uint8List?> read(String key) async {
    reads++;
    return data[key];
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    writes++;
    data[key] = bytes;
  }

  @override
  Future<void> clear() async {
    clears++;
    data.clear();
  }
}
