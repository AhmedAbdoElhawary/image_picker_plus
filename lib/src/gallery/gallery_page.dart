import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_route.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/gallery/album_picker.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/gallery_grid.dart';
import 'package:image_picker_plus/src/gallery/gallery_layout.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  GalleryController? _controller;
  final ValueNotifier<bool> _finishing = ValueNotifier(false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = PickerScope.of(context);
    _controller = GalleryController(service: scope.services.gallery!, settings: scope.settings)..init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _finishing.dispose();
    super.dispose();
  }

  void _onTap(MediaItem item) {
    if (_controller!.toggle(item)) return;
    final scope = PickerScope.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(scope.texts.maxReachedFor(scope.settings.maxSelection))));
  }

  Future<void> _next() async {
    final controller = _controller!;
    if (_finishing.value || controller.selection.value.isEmpty) return;
    final scope = PickerScope.of(context);
    if (scope.settings.editing) {
      final items = await Navigator.of(context).push<List<PickedItem>>(
        PickerRoute(
          context: context,
          builder: (_) => scope.wrap(
            EditPage(
              items: controller.selection.value,
              crops: controller.crops,
              filterIndexes: controller.filterIndexes,
            ),
          ),
        ),
      );
      if (items != null && mounted) Navigator.of(context).pop(items);
      return;
    }
    _finishing.value = true;
    final items = await controller.pickedItems();
    if (!mounted) return;
    _finishing.value = false;
    Navigator.of(context).pop(items);
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final controller = _controller!;
    return ValueListenableBuilder<GalleryState>(
      valueListenable: controller.state,
      builder: (context, state, _) => Scaffold(
        key: const ValueKey(GalleryState.ready),
        backgroundColor: scope.theme.background,
        appBar: PickerAppBar(
          title: AlbumPicker(controller: controller),
          onClose: _close,
          action: AnimatedSwitcher(
            duration: PickerDurations.of(context).medium,
            child: state == GalleryState.ready
                ? _NextButton(controller: controller, busy: _finishing, onPressed: _next)
                : const SizedBox.shrink(),
          ),
        ),
        body: AnimatedSwitcher(
          duration: PickerDurations.of(context).medium,
          child: switch (state) {
            GalleryState.denied => MessageView(
              scope.texts.accessDenied,
              key: const ValueKey(GalleryState.denied),
              actionText: scope.texts.openSettings,
              onAction: scope.services.gallery!.openSettings,
            ),
            GalleryState.empty => MessageView(scope.texts.noImages, key: const ValueKey(GalleryState.empty)),
            _ => Column(
              children: [
                _LimitedBar(controller: controller),
                Expanded(
                  child: state == GalleryState.loading
                      ? const LoadingBox()
                      : GalleryLayout(
                          preview: scope.settings.showPreview ? MediaPreview(controller: controller) : null,
                          reveal: controller.preview,
                          grid: (padding) => GalleryGrid(controller: controller, onTap: _onTap, padding: padding),
                        ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final GalleryController controller;
  final ValueNotifier<bool> busy;
  final VoidCallback onPressed;

  const _NextButton({required this.controller, required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Selector<bool>(
      listenable: Listenable.merge([controller.selection, busy]),
      select: () => controller.selection.value.isEmpty || busy.value,
      builder: (context, disabled, _) => TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: scope.theme.accent,
          minimumSize: const Size(PickerLayout.minTouch, PickerLayout.minButtonTouchHeight),
        ),
        child: Text(
          scope.texts.next,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scope.theme.accent, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _LimitedBar extends StatelessWidget {
  final GalleryController controller;

  const _LimitedBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<GalleryAccess>(
      valueListenable: controller.access,
      builder: (context, access, _) {
        if (access != GalleryAccess.limited) return const SizedBox.shrink();
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () async {
              await scope.services.gallery!.manageLimitedAccess();
              await controller.reload();
            },
            style: TextButton.styleFrom(foregroundColor: scope.theme.accent),
            child: Text(scope.texts.manageAccess),
          ),
        );
      },
    );
  }
}
