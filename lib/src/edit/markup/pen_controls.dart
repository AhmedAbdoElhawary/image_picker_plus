import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// a row of the developer's colors, the chosen one ringed.
class ColorRow extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onChanged;

  const ColorRow({required this.colors, required this.selected, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return SizedBox(
      height: PickerLayout.minTouch,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: PickerLayout.padding / 2),
        children: [
          for (final color in colors)
            Semantics(
              button: true,
              selected: color == selected,
              label: scope.texts.color,
              child: InkResponse(
                onTap: () => onChanged(color),
                child: SizedBox.square(
                  dimension: PickerLayout.minTouch,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == selected ? scope.theme.accent : scope.theme.onSurfaceMuted,
                          width: color == selected ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// colors, three sizes and the eraser.
class PenControls extends StatelessWidget {
  /// parts of the image width.
  static const List<double> widths = [0.006, 0.012, 0.024];
  static const double eraserWidth = 0.03;

  final List<Color> colors;
  final Color color;
  final double width;
  final bool erasing;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onWidth;
  final ValueChanged<bool> onErasing;

  const PenControls({
    required this.colors,
    required this.color,
    required this.width,
    required this.erasing,
    required this.onColor,
    required this.onWidth,
    required this.onErasing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (index, value) in widths.indexed)
              Semantics(
                button: true,
                selected: !erasing && value == width,
                label: scope.texts.size,
                child: InkResponse(
                  onTap: () {
                    onErasing(false);
                    onWidth(value);
                  },
                  child: SizedBox.square(
                    dimension: PickerLayout.minTouch,
                    child: Center(
                      child: Container(
                        width: 8.0 + index * 8,
                        height: 8.0 + index * 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !erasing && value == width ? scope.theme.accent : scope.theme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              onPressed: () => onErasing(!erasing),
              tooltip: scope.texts.eraser,
              isSelected: erasing,
              icon: Icon(
                Icons.auto_fix_normal_outlined,
                color: erasing ? scope.theme.accent : scope.theme.onSurface,
              ),
            ),
          ],
        ),
        ColorRow(
          colors: colors,
          selected: color,
          onChanged: (value) {
            onErasing(false);
            onColor(value);
          },
        ),
      ],
    );
  }
}
