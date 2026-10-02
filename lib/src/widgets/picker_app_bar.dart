import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

class PickerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final VoidCallback? onClose;
  final IconData closeIcon;
  final Widget? action;
  final Color? color;
  const PickerAppBar({
    this.title,
    this.color,
    this.onClose,
    this.closeIcon = Icons.close_rounded,
    this.action,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);
  Widget getCloseIcon(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;

    return IconButton(
      onPressed: onClose,
      tooltip: scope.texts.close,
      icon: Icon(closeIcon, color: theme.onSurface, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;

    if (action == null && title == null && onClose != null) {
      return Container(
        decoration: BoxDecoration(
          color: color ?? theme.background,
          borderRadius: const BorderRadius.all(Radius.circular(50)),
        ),
        child: getCloseIcon(context),
      );
    }
    return Material(
      color: color ?? theme.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: PickerLayout.padding / 4),
            child: Row(
              children: [
                if (onClose != null) getCloseIcon(context),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: theme.onSurface),
                    child: Align(alignment: AlignmentDirectional.centerStart, child: title),
                  ),
                ),
                ?action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
