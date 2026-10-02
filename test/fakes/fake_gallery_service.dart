import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:image_picker_plus/src/models/album.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

/// a 1x1 transparent png, enough for image widgets in tests.
final Uint8List tinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82,
]);

MediaItem fakeItem(String id, {MediaType type = MediaType.image}) => MediaItem(
  id: id,
  type: type,
  width: 400,
  height: 300,
  modified: DateTime(2026),
  duration: type == MediaType.video ? const Duration(seconds: 75) : Duration.zero,
);

class FakeGalleryService implements GalleryService {
  GalleryAccess access;

  /// album id to its items.
  final Map<String, List<MediaItem>> data;
  final List<Album> albumList;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  final List<(String, int)> pageCalls = [];
  int thumbnailCalls = 0;
  int openSettingsCalls = 0;
  int manageCalls = 0;
  Completer<void>? itemsGate;

  FakeGalleryService({this.access = GalleryAccess.full, Map<String, List<MediaItem>>? data})
    : data = data ?? {"all": List.generate(200, (i) => fakeItem("$i"))},
      albumList = [];

  factory FakeGalleryService.withItems(int count, {GalleryAccess access = GalleryAccess.full}) =>
      FakeGalleryService(access: access, data: {"all": List.generate(count, (i) => fakeItem("$i"))});

  void emitChange() => _changes.add(null);

  @override
  Future<GalleryAccess> requestAccess() async => access;

  @override
  Future<List<Album>> albums(MediaType type) async => [
    for (final entry in data.entries) Album(id: entry.key, name: entry.key, count: entry.value.length),
  ];

  @override
  Future<List<MediaItem>> items(Album album, {required int page, required int size}) async {
    pageCalls.add((album.id, page));
    await itemsGate?.future;
    final all = data[album.id] ?? const [];
    final start = page * size;
    if (start >= all.length) return const [];
    return all.sublist(start, (start + size).clamp(0, all.length));
  }

  @override
  Future<Uint8List?> thumbnail(MediaItem item, int size) async {
    thumbnailCalls++;
    return tinyPng;
  }

  @override
  Future<XFile?> file(MediaItem item) async =>
      XFile.fromData(tinyPng, path: "/fake/${item.id}", name: item.id);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> openSettings() async => openSettingsCalls++;

  @override
  Future<void> manageLimitedAccess() async => manageCalls++;
}
