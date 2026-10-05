import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';

/// over everything in the root overlay, also over the app bar and the wide card,
/// and the page under it takes no taps, back or keys while saving.
class ExportingOverlay extends StatefulWidget {
  final EditController controller;
  final Widget child;

  const ExportingOverlay({required this.controller, required this.child, super.key});

  @override
  State<ExportingOverlay> createState() => ExportingOverlayState();
}

class ExportingOverlayState extends State<ExportingOverlay> {
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
      overlayChildBuilder: (context) => const ProcessingPopup(),
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

class ProcessingPopup extends StatelessWidget {
  const ProcessingPopup({super.key});

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
                  Text(
                    scope.texts.processing,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scope.theme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
