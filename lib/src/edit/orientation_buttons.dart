import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';

/// rotate left and flip, under the image on the edit page.
class OrientationButtons extends StatelessWidget {
  final CropController controller;

  const OrientationButtons({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (scope.settings.rotate)
          _RoundButton(
            icon: Icons.rotate_90_degrees_ccw_rounded,
            label: scope.texts.rotate,
            onTap: controller.rotate,
          ),
        if (scope.settings.rotate && scope.settings.flip) const SizedBox(width: 6.5),
        if (scope.settings.flip)
          _RoundButton(icon: Icons.flip_rounded, label: scope.texts.flip, onTap: controller.flip),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: theme.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: PickerLayout.minTouch * 0.8,
              child: Icon(icon, size: 20, color: theme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
