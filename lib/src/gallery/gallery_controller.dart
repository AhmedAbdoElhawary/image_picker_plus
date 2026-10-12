import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/export_item.dart';
import 'package:image_picker_plus/src/edit/image_edits.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/gallery/preselection.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/album.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

enum GalleryState { loading, ready, denied, empty, failed }

class GalleryController {
  static const int pageSize = 20;

  /// the pages after the first, big since each one builds the grid again.
  static const int restSize = 500;

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

  /// pages of [restSize] loaded.
  int _page = 0;
  bool _disposed = false;

  // a newer album switch or reload makes older page results stale
  int _generation = 0;
  StreamSubscription<void>? _changes;

  /// the edits of each selected image, kept while it stays selected.
  final ImageEdits edits = ImageEdits();
  Map<String, CropController> get crops => edits.crops;
  Map<String, ValueNotifier<int>> get filterIndexes => edits.filterIndexes;
  Map<String, MarkupController> get markups => edits.markups;
  Map<String, ValueNotifier<Adjustments>> get adjustments => edits.adjustments;

  /// finds an earlier pick again, run only after access is given since lookups fail without it.
  final Future<Preselection> Function()? preselect;

  /// the first album load keeps the preselection instead of selecting its first item.
  bool _preselected = false;

  GalleryController({required this.service, required this.settings, this.preselect}) {
    selection.addListener(_syncEdits);
  }

  void _syncEdits() {
    edits.keep({for (final item in selection.value) item.id});
    edits.prepare(selection.value, settings);
  }

  /// runs again from the retry after a failure.
  Future<void> init() async {
    state.value = GalleryState.loading;
    try {
      access.value = await service.requestAccess();
      if (_disposed) return;
      if (access.value == GalleryAccess.denied) {
        state.value = GalleryState.denied;
        return;
      }
      // a retry doesn't listen or preselect again
      if (_changes == null) {
        _changes = service.changes.listen((_) => reload());
        final preselect = this.preselect;
        if (preselect != null) {
          final preselection = await preselect();
          if (_disposed) return;
          _preselect(preselection);
        }
      }
      await _loadAlbums();
    } catch (_) {
      _fail(_generation);
    }
  }

  /// a stale load failing doesn't hide the newer one.
  void _fail(int generation) {
    if (!_disposed && generation == _generation) state.value = GalleryState.failed;
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
    final List<MediaItem> page;
    try {
      page = await service.items(next, page: 0, size: pageSize);
    } catch (_) {
      _fail(generation);
      return;
    }
    if (_disposed || generation != _generation) return;
    items.value = page;
    if (page.length < pageSize) ended.value = true;
    if (items.value.isEmpty) {
      state.value = GalleryState.empty;
      return;
    }
    state.value = GalleryState.ready;
    if (_preselected) {
      _preselected = false;
    } else {
      final first = items.value.first;
      preview.value = first;
      if (!multi.value) selection.value = [first];
    }
    unawaited(_loadRest(next, generation));
  }

  /// stops when the album changes or reloads, they start their own.
  Future<void> _loadRest(Album current, int generation) async {
    try {
      while (!_disposed && generation == _generation && !ended.value) {
        final page = await service.items(current, page: _page, size: restSize);
        if (_disposed || generation != _generation) return;
        // the first big page has the small first one in it, so it takes its place
        items.value = _page == 0 ? page : [...items.value, ...page];
        _page++;
        if (page.length < restSize) ended.value = true;
      }
    } catch (_) {
      _fail(generation);
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
    try {
      for (var page = 0; page < pages && !end; page++) {
        final list = await service.items(current, page: page, size: restSize);
        if (_disposed || generation != _generation) return;
        fresh.addAll(list);
        end = list.length < restSize;
      }
    } catch (_) {
      _fail(generation);
      return;
    }
    final now = fresh.toSet();
    _page = pages;
    items.value = fresh;
    ended.value = end;
    selection.value = selection.value.where((item) => !before.contains(item) || now.contains(item)).toList();
    final shown = preview.value;
    if (shown != null && before.contains(shown) && !now.contains(shown)) {
      preview.value = selection.value.isNotEmpty
          ? selection.value.last
          : (fresh.isEmpty ? null : fresh.first);
    }
    state.value = fresh.isEmpty ? GalleryState.empty : GalleryState.ready;
    unawaited(_loadRest(current, generation));
  }

  void _preselect(Preselection preselection) {
    final items = preselection.items;
    if (items.isEmpty) return;
    _preselected = true;
    // no preview means no ratio picker, so only the image's own ratio is there
    preselection.restore(edits, settings: settings, ratios: settings.cropRatios);
    multi.value = settings.multi;
    selection.value = items;
    preview.value = items.first;
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
  void selectTaken(MediaItem item, ImageEdits taken) {
    edits.addAll(taken);
    selection.value = [item];
  }

  /// 1 based order in the selection, 0 when not selected.
  int orderOf(MediaItem item) => selection.value.indexOf(item) + 1;

  /// for when editing is off, the output limits still apply.
  Future<List<PickedItem>> pickedItems(PickerServices services) async {
    final picked = await Future.wait(
      selection.value.map((item) => exportItem(services: services, output: settings.output, item: item)),
    );
    return picked.nonNulls.toList();
  }

  void dispose() {
    _disposed = true;
    _changes?.cancel();
    edits.dispose();
    for (final notifier in [state, access, albums, album, items, selection, preview, ended, multi, adding]) {
      notifier.dispose();
    }
  }
}
