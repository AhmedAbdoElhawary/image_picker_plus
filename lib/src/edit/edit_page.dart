import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/filter_strip.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/edit/reorder_strip.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';
import 'package:image_picker_plus/src/gallery/ratio_button.dart';
import 'package:image_picker_plus/src/gallery/video_preview.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

class EditPage extends StatefulWidget {
  final List<MediaItem> items;
  final Map<String, CropController> crops;
  final Map<String, ValueNotifier<int>> filterIndexes;

  /// a camera photo has no gallery preview to pick the ratio in, so it's picked here.
  final bool changeRatio;

  /// null pops, the system picker flow picks again instead.
  final VoidCallback? onBack;

  /// shown first, null shows the first item.
  final MediaItem? initial;

  /// null hides the plus after the items.
  final VoidCallback? onAdd;

  /// so the page that opened this keeps the order set here.
  final ValueChanged<List<MediaItem>>? onReorder;

  const EditPage({
    required this.items,
    this.crops = const {},
    this.filterIndexes = const {},
    this.changeRatio = false,
    this.onBack,
    this.initial,
    this.onAdd,
    this.onReorder,
    super.key,
  });

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  EditController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = PickerScope.of(context);
    _controller = EditController(
      services: scope.services,
      output: scope.settings.output,
      items: widget.items,
      initial: widget.initial,
      crops: widget.crops,
      filterIndexes: widget.filterIndexes,
    );
    final onReorder = widget.onReorder;
    final items = _controller!.items;
    if (onReorder != null) items.addListener(() => onReorder(items.value));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final controller = _controller!;
    if (controller.exporting.value) return;
    final texts = PickerScope.of(context).texts;
    try {
      final items = await controller.export();
      if (mounted) Navigator.of(context).pop(items);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texts.exportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final controller = _controller!;
    final back = widget.onBack ?? () => Navigator.of(context).pop();
    return _ExportingOverlay(
      controller: controller,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): back,
          const SingleActivator(LogicalKeyboardKey.enter): _done,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: scope.theme.background,
            appBar: PickerAppBar(
              title: const SizedBox.shrink(),
              closeIcon: Icons.arrow_back_rounded,
              onClose: back,
              action: TextButton(
                onPressed: _done,
                style: TextButton.styleFrom(
                  foregroundColor: scope.theme.accent,
                  minimumSize: const Size(PickerLayout.minTouch, PickerLayout.minButtonTouchHeight),
                ),
                child: Text(
                  scope.texts.done,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scope.theme.accent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: _CurrentItem(controller: controller, changeRatio: widget.changeRatio),
                  ),
                  if (scope.settings.filters) FilterStrip(controller: controller),
                  if (widget.items.length > 1) ReorderStrip(controller: controller, onAdd: widget.onAdd),
                  const SizedBox(height: PickerLayout.padding / 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentItem extends StatelessWidget {
  final EditController controller;
  final bool changeRatio;

  const _CurrentItem({required this.controller, required this.changeRatio});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<MediaItem>(
      valueListenable: controller.current,
      builder: (context, item, _) {
        final crop = controller.crops[item.id];
        final image = _FilteredImage(item: item, filter: controller.filterIndexes[item.id], crop: crop);
        final Widget child;
        if (item.isVideo) {
          child = Column(
            key: ObjectKey(item),
            children: [
              // a picked file has no gallery thumbnail, so it plays instead
              Expanded(
                child: item.path != null ? VideoPreview(item: item) : PreviewImage(item: item),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(PickerLayout.padding),
                child: Text(scope.texts.videoNotEditable, style: TextStyle(color: scope.theme.onSurfaceMuted)),
              ),
            ],
          );
        } else if (crop != null) {
          child = Stack(
            key: ObjectKey(item),
            children: [
              CropView(controller: crop, image: image),
              if (changeRatio && scope.settings.cropRatios.length > 1)
                PositionedDirectional(
                  start: PickerLayout.padding,
                  bottom: PickerLayout.ratioButtonBottomPadding,
                  child: RatioButton(controller: crop),
                ),
            ],
          );
        } else {
          final aspect = item.width / item.height;
          child = Center(
            key: ObjectKey(item),
            child: AspectRatio(aspectRatio: aspect.isFinite && aspect > 0 ? aspect : 1, child: image),
          );
        }
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: PickerLayout.padding * 0.8),
          child: AnimatedSwitcher(duration: PickerDurations.of(context).short, child: child),
        );
      },
    );
  }
}

/// only this rebuilds when the filter changes, not the crop around it.
class _FilteredImage extends StatelessWidget {
  final MediaItem item;
  final ValueNotifier<int>? filter;
  final CropController? crop;

  const _FilteredImage({required this.item, required this.filter, required this.crop});

  @override
  Widget build(BuildContext context) {
    final image = PreviewImage(item: item, fit: BoxFit.fill, crop: crop);
    final filter = this.filter;
    if (filter == null) return image;
    return ValueListenableBuilder<int>(
      valueListenable: filter,
      builder: (context, index, image) => ColorFiltered(colorFilter: ColorFilter.matrix(filters[index]), child: image),
      child: image,
    );
  }
}

/// over everything in the root overlay, also over the app bar and the wide card,
/// and the page under it takes no taps, back or keys while saving.
class _ExportingOverlay extends StatefulWidget {
  final EditController controller;
  final Widget child;

  const _ExportingOverlay({required this.controller, required this.child});

  @override
  State<_ExportingOverlay> createState() => _ExportingOverlayState();
}

class _ExportingOverlayState extends State<_ExportingOverlay> {
  final OverlayPortalController _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    widget.controller.exporting.addListener(_toggle);
  }

  @override
  void dispose() {
    widget.controller.exporting.removeListener(_toggle);
    super.dispose();
  }

  void _toggle() => widget.controller.exporting.value ? _portal.show() : _portal.hide();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context) => const _ProcessingPopup(),
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.controller.exporting,
        builder: (context, exporting, child) => PopScope(
          canPop: !exporting,
          // takes the focus off the page, so esc, enter and the strips do nothing
          child: ExcludeFocus(excluding: exporting, child: child!),
        ),
        child: widget.child,
      ),
    );
  }
}

class _ProcessingPopup extends StatelessWidget {
  const _ProcessingPopup();

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: scope.theme.barrier,
        child: Center(
          // material for the text style, the overlay is above the page's scaffold
          child: Material(
            color: scope.theme.surface,
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 30, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // it spins every frame, alone it doesn't repaint the popup with it
                  RepaintBoundary(
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: scope.theme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(scope.texts.processing, style: TextStyle(color: scope.theme.onSurface)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
