import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/gallery/gallery_controller.dart';

/// starts counting from the shown item, and cancel goes back to it alone. hidden while adding from the edit page.
class SelectButton extends StatelessWidget {
  final GalleryController controller;

  const SelectButton({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: controller.adding,
      builder: (context, adding, child) => adding ? const SizedBox.shrink() : child!,
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.multi,
        builder: (context, multi, _) => Semantics(
          button: true,
          child: Material(
            color: scope.theme.surface,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => multi ? controller.cancelMulti() : controller.startMulti(controller.preview.value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: PickerLayout.minTouch * 0.8,
                  minWidth: PickerLayout.minTouch,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      multi ? scope.texts.cancel : scope.texts.select,
                      style: TextStyle(color: scope.theme.onSurface, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
