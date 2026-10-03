import 'dart:typed_data';

abstract class CacheService {
  Future<Uint8List?> read(String key);

  Future<void> write(String key, Uint8List bytes);

  Future<void> clear();
}
