import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/edit_frame.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/files/files_picker.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/gallery/preselection.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

/// the edit page for files from the system picker, back picks again instead of going to a gallery.
class FilesFlow extends StatefulWidget {
  final List<XFile> files;

  /// an earlier pick, opened as is without reading [files].
  final Preselection? preselection;

  const FilesFlow({this.files = const [], this.preselection, super.key})
    : assert(files.length > 0 || preselection != null);

  @override
  State<FilesFlow> createState() => _FilesFlowState();
}

class _FilesFlowState extends State<FilesFlow> {
  /// in the order set on the edit page.
  List<MediaItem>? _items;

  /// shown first on the edit page, the first added one after adding.
  MediaItem? _initial;
  final Map<String, CropController> _crops = {};
  final Map<String, ValueNotifier<int>> _filterIndexes = {};
  final Map<String, MarkupController> _markups = {};

  /// goes up on each back, an older pick that comes back late is dropped.
  int _generation = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final preselection = widget.preselection;
    if (preselection == null) {
      _read(widget.files, _generation);
      return;
    }
    final settings = PickerScope.of(context).settings;
    final (crops, filters, markups) = preselection.restore(
      ratios: settings.cropRatios,
      filters: settings.filters,
      markup: settings.markup,
    );
    _crops.addAll(crops);
    _filterIndexes.addAll(filters);
    _markups.addAll(markups);
    _prepare(preselection.items);
    _items = preselection.items;
  }

  @override
  void dispose() {
    _clear();
    evictMediaImages();
    super.dispose();
  }

  Future<void> _read(List<XFile> files, int generation) async {
    final scope = PickerScope.of(context);
    final settings = scope.settings;
    final pick = await FilesPicker(services: scope.services, settings: settings).read(files);
    if (!mounted || generation != _generation) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    pick.showMessages(messenger, settings);
    if (pick.items.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _clear();
    _prepare(pick.items);
    setState(() {
      _items = pick.items;
      _initial = null;
    });
  }

  void _prepare(List<MediaItem> items) {
    final settings = PickerScope.of(context).settings;
    for (final item in items) {
      if (item.isVideo) continue;
      if (settings.cropRatios.isNotEmpty) {
        final aspect = item.height == 0 ? 1.0 : item.width / item.height;
        _crops.putIfAbsent(
          item.id,
          () => CropController(imageAspect: aspect, ratio: settings.cropRatios.first),
        );
      }
      if (settings.filters) _filterIndexes.putIfAbsent(item.id, () => ValueNotifier(0));
      if (settings.markup.enabled) _markups.putIfAbsent(item.id, MarkupController.new);
    }
  }

  /// the new files go after the ones there, only as many as still fit.
  void _add() {
    final scope = PickerScope.of(context);
    final generation = _generation;
    // no await before open, browsers only allow it right after the click
    scope.services.files.open(multi: true, type: scope.settings.mediaType).then((files) async {
      final items = _items;
      if (!mounted || generation != _generation || items == null || files.isEmpty) return;
      // the same file again would be two items with one id
      final fresh = files.where((file) => !items.any((item) => item.path == file.path)).toList();
      final room = scope.settings.maxSelection - items.length;
      final pick = await FilesPicker(
        services: scope.services,
        settings: scope.settings,
      ).read(fresh, room: room);
      if (!mounted || generation != _generation) return;
      pick.showMessages(ScaffoldMessenger.maybeOf(context), scope.settings);
      final added = pick.items;
      if (added.isEmpty) return;
      _prepare(added);
      setState(() {
        _generation++;
        _items = [..._items!, ...added];
        _initial = added.first;
      });
    });
  }

  void _repick() {
    final scope = PickerScope.of(context);
    final generation = ++_generation;
    // no await before open, browsers only allow it right after the click
    scope.services.files.open(multi: scope.settings.multi, type: scope.settings.mediaType).then((files) {
      if (!mounted || generation != _generation) return;
      if (files.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _items = null);
      _read(files, generation);
    });
  }

  void _clear() {
    for (final crop in _crops.values) {
      crop.dispose();
    }
    for (final filter in _filterIndexes.values) {
      filter.dispose();
    }
    for (final markup in _markups.values) {
      markup.dispose();
    }
    _crops.clear();
    _filterIndexes.clear();
    _markups.clear();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) {
      return EditFrame(
        child: ColoredBox(color: PickerScope.of(context).theme.background, child: const LoadingBox()),
      );
    }
    return EditFrame(
      child: EditPage(
        key: ValueKey(_generation),
        items: items,
        initial: _initial,
        crops: _crops,
        filterIndexes: _filterIndexes,
        markups: _markups,
        onBack: _repick,
        onAdd: _add,
        onReorder: (items) => _items = items,
      ),
    );
  }
}
