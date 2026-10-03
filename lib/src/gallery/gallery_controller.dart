import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/models/album.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

enum GalleryState { loading, ready, denied, empty }

class GalleryController {
  static const int pageSize = 20;

  final GalleryService service;
  final PickerSettings settings;

  final ValueNotifier<GalleryState> state = ValueNotifier(GalleryState.loading);
  final ValueNotifier<GalleryAccess> access = ValueNotifier(GalleryAccess.full);
  final ValueNotifier<List<Album>> albums = ValueNotifier(const []);
  final ValueNotifier<Album?> album = ValueNotifier(null);
  final ValueNotifier<List<MediaItem>> items = ValueNotifier(const []);
  final ValueNotifier<List<MediaItem>> selection = ValueNotifier(const []);
  final ValueNotifier<MediaItem?> preview = ValueNotifier(null);
  final ValueNotifier<bool> ended = ValueNotifier(false);

  /// counting more than one, starts on a long press or the select button.
  final ValueNotifier<bool> multi = ValueNotifier(false);

  /// opened again from the edit page's plus, next adds to what's there.
  final ValueNotifier<bool> adding = ValueNotifier(false);

  int _page = 0;
  bool _disposed = false;

  // a newer album switch or reload makes older page results stale
  int _generation = 0;
  StreamSubscription<void>? _changes;

  /// one crop and filter per selected image, kept while it stays selected.
  /// the edit page shares them, so going back shows what was changed there.
  final Map<String, CropController> crops = {};
  final Map<String, ValueNotifier<int>> filterIndexes = {};

  GalleryController({required this.service, required this.settings}) {
    selection.addListener(_syncEdits);
  }

  void _syncEdits() {
    final ids = {for (final item in selection.value) item.id};
    crops.removeWhere((id, crop) {
      if (ids.contains(id)) return false;
      crop.dispose();
      return true;
    });
    filterIndexes.removeWhere((id, filter) {
      if (ids.contains(id)) return false;
      filter.dispose();
      return true;
    });
    for (final item in selection.value) {
      if (item.isVideo) continue;
      if (settings.cropRatios.isNotEmpty && !crops.containsKey(item.id)) {
        final aspect = item.height == 0 ? 1.0 : item.width / item.height;
        // no preview means no ratio picker, so the edit page crops at the image's own ratio
        final ratio = settings.showPreview ? settings.cropRatios.first : CropRatio.original;
        crops[item.id] = CropController(imageAspect: aspect, ratio: ratio);
      }
      if (settings.filters) filterIndexes.putIfAbsent(item.id, () => ValueNotifier(0));
    }
  }

  Future<void> init() async {
    access.value = await service.requestAccess();
    if (_disposed) return;
    if (access.value == GalleryAccess.denied) {
      state.value = GalleryState.denied;
      return;
    }
    _changes = service.changes.listen((_) => reload());
    await _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final list = await service.albums(settings.mediaType);
    if (_disposed) return;
    albums.value = list;
    if (list.isEmpty) {
      state.value = GalleryState.empty;
      return;
    }
    final current = album.value;
    await switchAlbum(list.firstWhere((a) => a == current, orElse: () => list.first));
  }

  /// shows the first item and keeps the counted ones, they can be from many albums.
  /// done after the first page, the rest keeps loading behind it.
  Future<void> switchAlbum(Album next) async {
    final generation = ++_generation;
    album.value = next;
    items.value = const [];
    ended.value = false;
    _page = 0;
    await _loadPage(next, generation);
    if (_disposed || generation != _generation) return;
    if (items.value.isEmpty) {
      state.value = GalleryState.empty;
      return;
    }
    state.value = GalleryState.ready;
    final first = items.value.first;
    preview.value = first;
    if (!multi.value) selection.value = [first];
    unawaited(_loadRest(next, generation));
  }

  Future<void> _loadPage(Album current, int generation) async {
    final page = await service.items(current, page: _page, size: pageSize);
    if (_disposed || generation != _generation) return;
    _page++;
    items.value = [...items.value, ...page];
    if (page.length < pageSize) ended.value = true;
  }

  /// stops when the album changes or reloads, they start their own.
  Future<void> _loadRest(Album current, int generation) async {
    while (!_disposed && generation == _generation && !ended.value) {
      await _loadPage(current, generation);
    }
  }

  /// reloads the same number of pages and drops selected items that are gone.
  Future<void> reload() async {
    final current = album.value;
    if (current == null || _disposed) return;
    final before = items.value.toSet();
    final pages = _page == 0 ? 1 : _page;
    final generation = ++_generation;
    final fresh = <MediaItem>[];
    var end = false;
    for (var page = 0; page < pages && !end; page++) {
      final list = await service.items(current, page: page, size: pageSize);
      if (_disposed || generation != _generation) return;
      fresh.addAll(list);
      end = list.length < pageSize;
    }
    final now = fresh.toSet();
    _page = pages;
    items.value = fresh;
    ended.value = end;
    selection.value = selection.value.where((item) => !before.contains(item) || now.contains(item)).toList();
    final shown = preview.value;
    if (shown != null && before.contains(shown) && !now.contains(shown)) {
      preview.value = selection.value.isNotEmpty ? selection.value.last : (fresh.isEmpty ? null : fresh.first);
    }
    state.value = fresh.isEmpty ? GalleryState.empty : GalleryState.ready;
    unawaited(_loadRest(current, generation));
  }

  /// false when the max is reached and the item wasn't added.
  bool toggle(MediaItem item) {
    final list = selection.value;
    if (!multi.value) {
      selection.value = [item];
      preview.value = item;
      return true;
    }
    if (list.contains(item)) {
      // first tap on a selected item that isn't shown just shows it
      if (preview.value != item) {
        preview.value = item;
        return true;
      }
      final rest = [...list]..remove(item);
      selection.value = rest;
      if (rest.isNotEmpty) preview.value = rest.last;
      return true;
    }
    if (list.length >= settings.maxSelection) return false;
    selection.value = [...list, item];
    preview.value = item;
    return true;
  }

  /// [first] is counted 1, null when nothing is shown yet.
  void startMulti(MediaItem? first) {
    if (!settings.multi) return;
    multi.value = true;
    if (first == null) return;
    selection.value = [first];
    preview.value = first;
  }

  /// keeps only the shown item.
  void cancelMulti() {
    multi.value = false;
    final shown = preview.value;
    selection.value = shown == null ? const [] : [shown];
  }

  /// a photo from the camera page becomes the only selected one, with the edits made on it there.
  void selectTaken(MediaItem item, {CropController? crop, ValueNotifier<int>? filterIndex}) {
    if (crop != null) crops[item.id] = crop;
    if (filterIndex != null) filterIndexes[item.id] = filterIndex;
    selection.value = [item];
  }

  /// 1 based order in the selection, 0 when not selected.
  int orderOf(MediaItem item) => selection.value.indexOf(item) + 1;

  Future<List<PickedItem>> pickedItems() async {
    final picked = <PickedItem>[];
    for (final item in selection.value) {
      final file = await service.file(item);
      if (file == null) continue;
      picked.add(PickedItem(file: file, type: item.type, width: item.width, height: item.height, edited: false));
    }
    return picked;
  }

  void dispose() {
    _disposed = true;
    _changes?.cancel();
    for (final notifier in [...crops.values, ...filterIndexes.values]) {
      notifier.dispose();
    }
    for (final notifier in [state, access, albums, album, items, selection, preview, ended, multi, adding]) {
      notifier.dispose();
    }
  }
}
