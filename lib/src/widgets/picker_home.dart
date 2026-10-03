import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/camera_page.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_route.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/widgets/picker_tabs.dart';

/// the root of the picker: one page, or the pages with tabs under them.
/// it opens the edit page, so the plus there can add from any tab.
class PickerHome extends StatefulWidget {
  const PickerHome({super.key});

  @override
  State<PickerHome> createState() => _PickerHomeState();
}

class _PickerHomeState extends State<PickerHome> {
  PickerTab? _current;

  /// made without the gallery tab too, it holds what the camera adds.
  GalleryController? _gallery;

  /// what the edit page had when its plus was tapped, back from adding puts it back.
  List<MediaItem> _beforeAdd = const [];

  /// the last photo's edits, kept until the next photo since the edit page uses them while it closes.
  CropController? _crop;
  ValueNotifier<int>? _filterIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gallery != null) return;
    final scope = PickerScope.of(context);
    _gallery = GalleryController(service: scope.services.gallery!, settings: scope.settings);
  }

  @override
  void dispose() {
    _gallery?.dispose();
    _crop?.dispose();
    _filterIndex?.dispose();
    super.dispose();
  }

  Future<void> _open(EditPage page) async {
    final scope = PickerScope.of(context);
    final items = await Navigator.of(
      context,
    ).push<List<PickedItem>>(PickerRoute(context: context, builder: (_) => scope.wrap(page)));
    if (items != null && mounted) Navigator.of(context).pop(items);
  }

  Future<void> _edit() {
    final gallery = _gallery!;
    final selection = gallery.selection.value;
    final before = _beforeAdd.toSet();
    _beforeAdd = const [];
    gallery.adding.value = false;
    return _open(
      EditPage(
        items: selection,
        // after adding, the first new one
        initial: selection.firstWhere((item) => !before.contains(item), orElse: () => selection.first),
        crops: gallery.crops,
        filterIndexes: gallery.filterIndexes,
        onAdd: _add,
        onReorder: (items) => gallery.selection.value = items,
      ),
    );
  }

  void _add() {
    final gallery = _gallery!;
    _beforeAdd = gallery.selection.value;
    // a single tap selection, the next tap would replace it instead of counting
    gallery.multi.value = true;
    gallery.adding.value = true;
    Navigator.of(context).pop();
  }

  void _cancelAdd() {
    _gallery!.selection.value = _beforeAdd;
    _edit();
  }

  void _close() => _gallery!.adding.value ? _cancelAdd() : Navigator.of(context).pop();

  Future<void> _taken(PickedItem picked) async {
    final gallery = _gallery!;
    final scope = PickerScope.of(context);
    final settings = scope.settings;
    final item = MediaItem(
      id: picked.file.path,
      type: picked.type,
      width: picked.width,
      height: picked.height,
      modified: DateTime.now(),
      path: picked.file.path,
    );
    if (gallery.adding.value) {
      final selection = gallery.selection.value;
      if (selection.length < settings.maxSelection) {
        gallery.selection.value = [...selection, item];
      } else {
        // the edit page opening next shows it
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(scope.texts.maxReachedFor(settings.maxSelection))));
      }
      return _edit();
    }
    if (item.isVideo || !settings.editing) {
      Navigator.of(context).pop([picked]);
      return;
    }
    _crop?.dispose();
    _filterIndex?.dispose();
    final crop = _crop = settings.cropRatios.isEmpty
        ? null
        : CropController(
            imageAspect: item.height == 0 ? 1 : item.width / item.height,
            ratio: settings.cropRatios.first,
          );
    final filterIndex = _filterIndex = settings.filters ? ValueNotifier(0) : null;
    return _open(
      EditPage(
        items: [item],
        crops: {item.id: ?crop},
        filterIndexes: {item.id: ?filterIndex},
        onAdd: () {
          // the gallery owns them from here
          _crop = null;
          _filterIndex = null;
          gallery.selectTaken(item, crop: crop, filterIndex: filterIndex);
          _add();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final tabs = PickerTabs.of(scope.settings);
    final current = _current ?? tabs.first;
    final hasGallery = tabs.contains(PickerTab.gallery);
    return ValueListenableBuilder<bool>(
      valueListenable: _gallery!.adding,
      builder: (context, adding, _) => PopScope(
        // system back while adding goes to the edit page too, not out of the picker
        canPop: !adding,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _cancelAdd();
        },
        child: ColoredBox(
          color: scope.theme.background,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // the gallery stays alive so its selection survives a trip to the camera
                    if (hasGallery)
                      Offstage(
                        offstage: current != PickerTab.gallery,
                        child: TickerMode(
                          enabled: current == PickerTab.gallery,
                          child: GalleryPage(controller: _gallery!, onEdit: _edit, onClose: _close),
                        ),
                      ),
                    // the camera is built only while shown, so it's released when leaving.
                    // no fade, two camera pages at once fight over the one camera
                    if (current != PickerTab.gallery)
                      SizedBox(
                        height: MediaQuery.of(context).size.height - (PickerLayout.pickerTabsHeight),
                        child: CameraPage(
                          key: ValueKey(current),
                          video: current == PickerTab.video,
                          adding: adding,
                          onTaken: _taken,
                          onClose: _close,
                        ),
                      ),
                  ],
                ),
              ),
              if (tabs.length > 1)
                PickerTabs(tabs: tabs, current: current, onChanged: (tab) => setState(() => _current = tab)),
            ],
          ),
        ),
      ),
    );
  }
}
