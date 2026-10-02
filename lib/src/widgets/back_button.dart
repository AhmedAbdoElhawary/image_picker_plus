import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onClose;
  final IconData closeIcon;
  final Color? color;
  const CustomBackButton({this.color, this.onClose, this.closeIcon = Icons.close_rounded, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            onTap: onClose,
            child: Container(
              decoration: BoxDecoration(
                color: color ?? theme.background,
                borderRadius: const BorderRadius.all(Radius.circular(50)),
              ),
              padding: const EdgeInsets.all(5),
              child: Icon(closeIcon, color: theme.onSurface, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
