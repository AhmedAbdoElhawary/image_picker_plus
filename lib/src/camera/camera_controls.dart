import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/capture_controller.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

class FlashButton extends StatelessWidget {
  final CaptureController controller;

  const FlashButton({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([controller.hasFlash, controller.flash]),
      builder: (context, _) {
        if (!controller.hasFlash.value) return const SizedBox.square(dimension: PickerLayout.minTouch);
        return IconButton(
          onPressed: controller.toggleFlash,
          tooltip: scope.texts.flash,
          icon: Icon(
            controller.flash.value ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            color: scope.theme.onSurface,
          ),
        );
      },
    );
  }
}

class SwitchCameraButton extends StatelessWidget {
  final CaptureController controller;

  const SwitchCameraButton({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: controller.cameraCount,
      builder: (context, count, _) {
        if (count < 2) return const SizedBox.square(dimension: PickerLayout.minTouch);
        return IconButton(
          onPressed: controller.switchCamera,
          tooltip: scope.texts.switchCamera,
          icon: Icon(Icons.cameraswitch_rounded, color: scope.theme.onSurface),
        );
      },
    );
  }
}
