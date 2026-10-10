import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/widgets/back_button.dart';

enum CloseButtonEnum { back, close }

class PickerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final VoidCallback? onClose;
  final CloseButtonEnum closeIcon;
  final Widget? action;
  final Color? color;
  const PickerAppBar({
    this.title,
    this.color,
    this.onClose,
    this.closeIcon = CloseButtonEnum.back,
    this.action,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(PickerLayout.appBarHeight);
  Widget getCloseIcon(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;

    return IconButton(
      onPressed: onClose,
      tooltip: scope.texts.close,
      icon: Icon(getIcon(context), color: theme.onSurface, size: 28),
    );
  }

  IconData getIcon(BuildContext context) => closeIcon == CloseButtonEnum.back
      ? defaultTargetPlatform == TargetPlatform.android
            ? Icons.arrow_back_rounded
            : Icons.arrow_back_ios_rounded
      : Icons.close_rounded;
  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;

    if (action == null && title == null && onClose != null) {
      return CustomCloseButton(onClose: onClose, color: color, closeIcon: getIcon(context));
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
