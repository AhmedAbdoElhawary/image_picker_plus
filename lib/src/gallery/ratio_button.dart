import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

/// cycles through the crop ratios the developer allows.
class RatioButton extends StatelessWidget {
  final CropController controller;

  const RatioButton({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final ratios = scope.settings.cropRatios;
    return Selector<CropRatio>(
      listenable: controller,
      select: () => controller.ratio,
      builder: (context, ratio) => Semantics(
        button: true,
        label: scope.texts.crop,
        child: Material(
          color: scope.theme.scrim,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => controller.ratio = ratios[(ratios.indexOf(ratio) + 1) % ratios.length],
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: PickerLayout.minTouch, minWidth: PickerLayout.minTouch),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.crop_rounded, size: 18, color: scope.theme.onAccent),
                    const SizedBox(width: 6),
                    Text(
                      ratio == CropRatio.original ? scope.texts.original : "$ratio",
                      style: TextStyle(color: scope.theme.onAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
