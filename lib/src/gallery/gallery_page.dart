import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/gallery/album_picker.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';
import 'package:image_picker_plus/src/gallery/gallery_grid.dart';
import 'package:image_picker_plus/src/gallery/gallery_layout.dart';
import 'package:image_picker_plus/src/gallery/media_preview.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

class GalleryPage extends StatefulWidget {
  final GalleryController controller;

  /// opens the edit page on the selection.
  final VoidCallback onEdit;
  final VoidCallback onClose;

  const GalleryPage({required this.controller, required this.onEdit, required this.onClose, super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ValueNotifier<bool> _finishing = ValueNotifier(false);
  late final Listenable _changes = Listenable.merge([widget.controller.state, widget.controller.adding]);

  @override
  void initState() {
    super.initState();
    widget.controller.init();
  }

  @override
  void dispose() {
    _finishing.dispose();
    super.dispose();
  }

  void _onTap(MediaItem item) {
    if (widget.controller.toggle(item)) return;
    final scope = PickerScope.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(scope.texts.maxReachedFor(scope.settings.maxSelection))));
  }

  void _onLongPress(MediaItem item) {
    final controller = widget.controller;
    if (!controller.settings.multi) return;
    if (controller.multi.value) return _onTap(item);
    // the strongest built in ones, vibrate on ios is a long buzz not a tap
    defaultTargetPlatform == TargetPlatform.iOS ? HapticFeedback.heavyImpact() : HapticFeedback.vibrate();
    controller.startMulti(item);
  }

  Future<void> _next() async {
    final controller = widget.controller;
    if (_finishing.value || controller.selection.value.isEmpty) return;
    if (controller.settings.editing) {
      widget.onEdit();
      return;
    }
    _finishing.value = true;
    final items = await controller.pickedItems();
    if (!mounted) return;
    _finishing.value = false;
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: _changes,
      builder: (context, _) {
        final state = controller.state.value;
        final adding = controller.adding.value;
        return Scaffold(
          key: const ValueKey(GalleryState.ready),
          backgroundColor: scope.theme.background,
          appBar: PickerAppBar(
            title: AlbumPicker(controller: controller),
            closeIcon: adding ? Icons.arrow_back_rounded : Icons.close_rounded,
            onClose: widget.onClose,
            action: AnimatedSwitcher(
              duration: PickerDurations.of(context).medium,
              child: state == GalleryState.ready
                  ? _NextButton(controller: controller, busy: _finishing, adding: adding, onPressed: _next)
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
              GalleryState.empty => MessageView(
                scope.texts.noImages,
                key: const ValueKey(GalleryState.empty),
              ),
              _ => Column(
                children: [
                  _LimitedBar(controller: controller),
                  Expanded(
                    child: state == GalleryState.loading
                        ? const LoadingBox()
                        : GalleryLayout(
                            preview: scope.settings.showPreview ? MediaPreview(controller: controller) : null,
                            reveal: controller.preview,
                            grid: (padding, collapse) => GalleryGrid(
                              controller: controller,
                              onTap: _onTap,
                              onLongPress: _onLongPress,
                              padding: padding,
                              collapse: collapse,
                            ),
                          ),
                  ),
                ],
              ),
            },
          ),
        );
      },
    );
  }
}

class _NextButton extends StatelessWidget {
  final GalleryController controller;
  final ValueNotifier<bool> busy;
  final bool adding;
  final VoidCallback onPressed;

  const _NextButton({
    required this.controller,
    required this.busy,
    required this.adding,
    required this.onPressed,
  });

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
          adding ? scope.texts.add : scope.texts.next,
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
