import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/edit_frame.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/files/files_picker.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

/// the edit page for files from the system picker, back picks again instead of going to a gallery.
class FilesFlow extends StatefulWidget {
  final List<XFile> files;

  const FilesFlow({required this.files, super.key});

  @override
  State<FilesFlow> createState() => _FilesFlowState();
}

class _FilesFlowState extends State<FilesFlow> {
  List<MediaItem>? _items;
  final Map<String, CropController> _crops = {};
  final Map<String, ValueNotifier<int>> _filterIndexes = {};

  /// goes up on each back, an older pick that comes back late is dropped.
  int _generation = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _read(widget.files, _generation);
  }

  @override
  void dispose() {
    _clear();
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
    for (final item in pick.items) {
      if (item.isVideo) continue;
      if (settings.cropRatios.isNotEmpty) {
        final aspect = item.height == 0 ? 1.0 : item.width / item.height;
        _crops[item.id] = CropController(imageAspect: aspect, ratio: settings.cropRatios.first);
      }
      if (settings.filters) _filterIndexes[item.id] = ValueNotifier(0);
    }
    setState(() => _items = pick.items);
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
    _crops.clear();
    _filterIndexes.clear();
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
        crops: _crops,
        filterIndexes: _filterIndexes,
        changeRatio: true,
        onBack: _repick,
      ),
    );
  }
}
