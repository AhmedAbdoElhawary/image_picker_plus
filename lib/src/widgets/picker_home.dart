import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/camera_page.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_route.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/edit/export_item.dart';
import 'package:image_picker_plus/src/edit/image_edits.dart';
import 'package:image_picker_plus/src/gallery/asset_thumbnail.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/gallery/preselection.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';
import 'package:image_picker_plus/src/widgets/picker_tabs.dart';

/// the root of the picker: one page, or the pages with tabs under them.
/// it opens the edit page, so the plus there can add from any tab.
class PickerHome extends StatefulWidget {
  /// an earlier pick to open with, empty opens like new.
  /// with editing on it opens on the edit page, the gallery only shows from its plus.
  final List<PickedItem> selected;

  const PickerHome({this.selected = const [], super.key});

  @override
  State<PickerHome> createState() => _PickerHomeState();
}

class _PickerHomeState extends State<PickerHome> {
  PickerTab? _current;

  /// made without the gallery tab too, it holds what the camera adds.
  GalleryController? _gallery;

  /// made once, so a tab switch or adding doesn't build the hidden gallery again.
  late final Widget _galleryPage = GalleryPage(controller: _gallery!, onEdit: _edit, onClose: _close);

  /// what the edit page had when its plus was tapped, back from adding puts it back.
  List<MediaItem> _beforeAdd = const [];

  /// the last photo's edits, kept until the next photo since the edit page uses them while it closes.
  ImageEdits _takenEdits = ImageEdits();

  /// opened on the edit page with [PickerHome.selected], so back there leaves the picker.
  bool _direct = false;

  /// the gallery hides under a loading box until the edit page covers it or the plus needs it.
  bool _hidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gallery != null) return;
    final scope = PickerScope.of(context);
    _gallery = GalleryController(
      service: scope.services.gallery!,
      settings: scope.settings,
      preselect: widget.selected.isEmpty ? null : _preselect,
    );
    // the earlier pick is found by the gallery page, a camera only picker has none
    _direct =
        widget.selected.isNotEmpty &&
        scope.settings.editing &&
        PickerTabs.of(scope.settings).contains(PickerTab.gallery);
    _hidden = _direct;
    if (_direct) _gallery!.state.addListener(_openDirect);
  }

  /// the gallery is ready only after the preselection, nothing found shows the gallery.
  void _openDirect() {
    final gallery = _gallery!;
    if (gallery.state.value == GalleryState.loading) return;
    gallery.state.removeListener(_openDirect);
    if (gallery.selection.value.isEmpty) return setState(() => _hidden = false);
    _edit();
  }

  Future<Preselection> _preselect() async {
    final scope = PickerScope.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final preselection = await Preselection.resolve(
      services: scope.services,
      settings: scope.settings,
      selected: widget.selected,
    );
    if (preselection.skipped && mounted) {
      messenger?.showSnackBar(SnackBar(content: Text(scope.texts.filesSkipped)));
    }
    return preselection;
  }

  @override
  void dispose() {
    _gallery?.dispose();
    _takenEdits.dispose();
    evictMediaImages();
    super.dispose();
  }

  Future<void> _open(EditPage page) async {
    final scope = PickerScope.of(context);
    final items = await Navigator.of(
      context,
    ).push<List<PickedItem>>(PickerRoute(context: context, builder: (_) => scope.wrap(page)));
    if (!mounted) return;
    if (items != null) return Navigator.of(context).pop(items);
    if (_direct && !_gallery!.adding.value) Navigator.of(context).pop();
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
        markups: gallery.markups,
        adjustments: gallery.adjustments,
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
    if (_hidden) setState(() => _hidden = false);
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
      await freeMediaImages();
      final done = await exportItem(services: scope.services, output: settings.output, item: item);
      if (mounted) Navigator.of(context).pop([?done]);
      return;
    }
    _takenEdits.dispose();
    final taken = _takenEdits = ImageEdits()..prepare([item], settings);
    return _open(
      EditPage(
        items: [item],
        crops: taken.crops,
        filterIndexes: taken.filterIndexes,
        markups: taken.markups,
        adjustments: taken.adjustments,
        onAdd: () {
          // the gallery owns them from here, and _takenEdits is left empty
          gallery.selectTaken(item, taken);
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              Offstage(
                offstage: _hidden,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          // the gallery stays alive so its selection survives a trip to the camera
                          if (hasGallery)
                            Offstage(
                              offstage: current != PickerTab.gallery,
                              child: TickerMode(enabled: current == PickerTab.gallery, child: _galleryPage),
                            ),
                          // the camera is built only while shown, so it's released when leaving.
                          // no fade, two camera pages at once fight over the one camera
                          if (current != PickerTab.gallery)
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height - (PickerLayout.pickerTabsHeight),
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
              if (_hidden) const LoadingBox(),
            ],
          ),
        ),
      ),
    );
  }
}
