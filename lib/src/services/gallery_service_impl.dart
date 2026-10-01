import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/models/album.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryServiceImpl implements GalleryService {
  // photo_manager works on its own entities, so the ones already loaded are kept by id
  final Map<String, AssetPathEntity> _paths = {};
  final Map<String, AssetEntity> _assets = {};

  @override
  Future<GalleryAccess> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend();
    if (state.isAuth) return GalleryAccess.full;
    if (state.hasAccess) return GalleryAccess.limited;
    return GalleryAccess.denied;
  }

  @override
  Future<List<Album>> albums(MediaType type) async {
    final paths = await PhotoManager.getAssetPathList(type: _requestType(type));
    paths.sort((a, b) => a.isAll == b.isAll ? 0 : (a.isAll ? -1 : 1));
    final albums = <Album>[];
    for (final path in paths) {
      _paths[path.id] = path;
      albums.add(Album(id: path.id, name: path.name, count: await path.assetCountAsync));
    }
    return albums;
  }

  @override
  Future<List<MediaItem>> items(Album album, {required int page, required int size}) async {
    final path = _paths[album.id];
    if (path == null) return const [];
    final assets = await path.getAssetListPaged(page: page, size: size);
    return [for (final asset in assets) ?_toItem(asset)];
  }

  @override
  Future<Uint8List?> thumbnail(MediaItem item, int size) async {
    final asset = await _asset(item.id);
    if (asset == null) return null;
    // short side at size, so a cover fit is never blurry
    final ratio = item.height == 0 ? 1.0 : item.width / item.height;
    final width = ratio >= 1 ? (size * ratio).round() : size;
    final height = ratio >= 1 ? size : (size / ratio).round();
    return asset.thumbnailDataWithSize(ThumbnailSize(width, height), quality: 90);
  }

  @override
  Future<XFile?> file(MediaItem item) async {
    final asset = await _asset(item.id);
    if (asset == null) return null;
    // cloud items can fail on the origin file, the edited copy still works
    final file = await asset.originFile ?? await asset.file;
    return file == null ? null : XFile(file.path);
  }

  @override
  Stream<void> get changes {
    late final StreamController<void> controller;
    void onChange(MethodCall _) => controller.add(null);
    controller = StreamController<void>(
      onListen: () {
        PhotoManager.addChangeCallback(onChange);
        PhotoManager.startChangeNotify();
      },
      onCancel: () {
        PhotoManager.removeChangeCallback(onChange);
        return PhotoManager.stopChangeNotify();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> openSettings() => PhotoManager.openSetting();

  @override
  Future<void> manageLimitedAccess() => PhotoManager.presentLimited();

  Future<AssetEntity?> _asset(String id) async => _assets[id] ?? await AssetEntity.fromId(id);

  MediaItem? _toItem(AssetEntity asset) {
    final type = switch (asset.type) {
      AssetType.image => MediaType.image,
      AssetType.video => MediaType.video,
      _ => null,
    };
    if (type == null) return null;
    _assets[asset.id] = asset;
    return MediaItem(
      id: asset.id,
      type: type,
      width: asset.orientatedWidth,
      height: asset.orientatedHeight,
      duration: asset.videoDuration,
      modified: asset.modifiedDateTime,
    );
  }

  static RequestType _requestType(MediaType type) => switch (type) {
    MediaType.image => RequestType.image,
    MediaType.video => RequestType.video,
    MediaType.all => RequestType.common,
  };
}
