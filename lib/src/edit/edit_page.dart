import 'package:flutter/material.dart';
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
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

class EditPage extends StatefulWidget {
  final List<MediaItem> items;
  final Map<String, CropController> crops;
  final Map<String, ValueNotifier<int>> filterIndexes;

  /// a camera photo has no gallery preview to pick the ratio in, so it's picked here.
  final bool changeRatio;

  const EditPage({
    required this.items,
    this.crops = const {},
    this.filterIndexes = const {},
    this.changeRatio = false,
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
      crops: widget.crops,
      filterIndexes: widget.filterIndexes,
    );
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
    return Scaffold(
      backgroundColor: scope.theme.background,
      appBar: PickerAppBar(
        title: const SizedBox.shrink(),
        closeIcon: Icons.arrow_back_rounded,
        onClose: () => Navigator.of(context).pop(),
        action: TextButton(
          onPressed: _done,
          style: TextButton.styleFrom(
            foregroundColor: scope.theme.accent,
            minimumSize: const Size(PickerLayout.minTouch, PickerLayout.minTouch),
          ),
          child: Text(scope.texts.done, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: _CurrentItem(controller: controller, changeRatio: widget.changeRatio),
                ),
                if (scope.settings.filters) FilterStrip(controller: controller),
                if (widget.items.length > 1) ReorderStrip(controller: controller),
                const SizedBox(height: PickerLayout.padding / 2),
              ],
            ),
          ),
          _ExportingOverlay(controller: controller),
        ],
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
        final image = _FilteredImage(item: item, filter: controller.filterIndexes[item.id]);
        final Widget child;
        if (item.isVideo) {
          child = Column(
            key: ObjectKey(item),
            children: [
              Expanded(child: PreviewImage(item: item)),
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

  const _FilteredImage({required this.item, required this.filter});

  @override
  Widget build(BuildContext context) {
    final image = PreviewImage(item: item, fit: BoxFit.fill);
    final filter = this.filter;
    if (filter == null) return image;
    return ValueListenableBuilder<int>(
      valueListenable: filter,
      builder: (context, index, image) => ColorFiltered(colorFilter: ColorFilter.matrix(filters[index]), child: image),
      child: image,
    );
  }
}

class _ExportingOverlay extends StatelessWidget {
  final EditController controller;

  const _ExportingOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: controller.exporting,
      builder: (context, exporting, _) {
        if (!exporting) return const SizedBox.shrink();
        return Positioned.fill(
          child: ColoredBox(
            color: scope.theme.scrim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: scope.theme.onAccent),
                  const SizedBox(height: PickerLayout.padding),
                  Text(scope.texts.exporting, style: TextStyle(color: scope.theme.onAccent)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
