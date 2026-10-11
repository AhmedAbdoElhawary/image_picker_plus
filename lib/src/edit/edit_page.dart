import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/edit_frame.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/edit_tools.dart';
import 'package:image_picker_plus/src/edit/exporting_overlay.dart';
import 'package:image_picker_plus/src/edit/filtered_image.dart';
import 'package:image_picker_plus/src/edit/markup/markup_buttons.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_view.dart';
import 'package:image_picker_plus/src/edit/orientation_buttons.dart';
import 'package:image_picker_plus/src/edit/reorder_strip.dart';
import 'package:image_picker_plus/src/gallery/ratio_button.dart';
import 'package:image_picker_plus/src/gallery/video_preview.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

class EditPage extends StatefulWidget {
  final List<MediaItem> items;
  final Map<String, CropController> crops;
  final Map<String, ValueNotifier<int>> filterIndexes;
  final Map<String, MarkupController> markups;
  final Map<String, ValueNotifier<Adjustments>> adjustments;

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
    this.markups = const {},
    this.adjustments = const {},
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

  /// the tools switch inside the markup page, only the first one opens it.
  bool _markupOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = PickerScope.of(context);
    _controller = EditController(
      services: scope.services,
      output: scope.settings.output,
      filters: scope.settings.filters,
      items: widget.items,
      initial: widget.initial,
      crops: widget.crops,
      filterIndexes: widget.filterIndexes,
      markups: widget.markups,
      adjustments: widget.adjustments,
    );
    _controller!.tool.addListener(_onTool);
    final onReorder = widget.onReorder;
    final items = _controller!.items;
    if (onReorder != null) items.addListener(() => onReorder(items.value));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTool() {
    if (_controller!.tool.value != null && !_markupOpen) _openMarkup();
  }

  /// a page of its own, so the image flies to it as a hero.
  Future<void> _openMarkup() async {
    final controller = _controller!;
    final scope = PickerScope.of(context);
    final duration = PickerDurations.of(context).medium;
    // in a card the markup is a card too, over this one
    final card = context.findAncestorWidgetOfExactType<EditFrame>() != null;
    final page = MarkupView(controller: controller);
    _markupOpen = true;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: !card,
        pageBuilder: (_, _, _) => scope.wrap(card ? EditFrame(child: page) : page),
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
    _markupOpen = false;
    if (mounted) controller.tool.value = null;
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
      final scope = PickerScope.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            texts.exportFailed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scope.theme.onSurface),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final controller = _controller!;
    final back = widget.onBack ?? () => Navigator.of(context).pop();
    return ExportingOverlay(
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
              title: MarkupButtons(controller: controller),
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
                  Expanded(child: _CurrentItem(controller: controller)),
                  EditTools(controller: controller),
                  if (widget.items.length > 1 ||
                      (widget.onAdd != null && widget.items.length < scope.settings.maxSelection))
                    ReorderStrip(controller: controller, onAdd: widget.onAdd),
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

  const _CurrentItem({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<MediaItem>(
      valueListenable: controller.current,
      builder: (context, item, _) {
        final crop = controller.crops[item.id];
        final markup = controller.markups[item.id];
        final image = FilteredImage(
          item: item,
          filter: controller.filterIndexes[item.id],
          adjustments: controller.adjustments[item.id],
          crop: crop,
          markup: markup,
        );
        final Widget child;
        if (item.isVideo) {
          child = Column(
            key: ObjectKey(item),
            children: [
              Expanded(child: VideoPreview(item: item, autoplay: false)),
              Padding(
                padding: const EdgeInsetsDirectional.all(PickerLayout.padding),
                child: Text(
                  scope.texts.videoNotEditable,
                  style: TextStyle(color: scope.theme.onSurfaceMuted, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
        } else if (crop != null) {
          child = Stack(
            key: ObjectKey(item),
            children: [
              CropView(controller: crop, image: image, heroTag: markup),
              if (scope.settings.cropRatios.length > 1)
                PositionedDirectional(
                  start: PickerLayout.padding,
                  bottom: PickerLayout.ratioButtonBottomPadding,
                  child: RatioButton(controller: crop),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: PickerLayout.ratioButtonBottomPadding,
                child: Center(child: OrientationButtons(controller: crop)),
              ),
            ],
          );
        } else {
          final aspect = item.width / item.height;
          child = Center(
            key: ObjectKey(item),
            child: AspectRatio(
              aspectRatio: aspect.isFinite && aspect > 0 ? aspect : 1,
              child: markup == null ? image : Hero(tag: markup, child: image),
            ),
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
