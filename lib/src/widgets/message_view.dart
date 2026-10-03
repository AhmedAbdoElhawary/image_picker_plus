import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/widgets/back_button.dart';

class MessageView extends StatelessWidget {
  final String text;
  final VoidCallback? onClose;
  final String? actionText;
  final VoidCallback? onAction;

  const MessageView(this.text, {this.onClose, this.actionText, this.onAction, super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;
    return ColoredBox(
      color: theme.background,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(PickerLayout.padding * 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: theme.onSurface, fontWeight: FontWeight.w600),
                    ),
                    if (actionText != null && onAction != null) ...[
                      const SizedBox(height: PickerLayout.padding),
                      FilledButton(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: theme.onAccent,
                          minimumSize: const Size(0, PickerLayout.minTouch),
                        ),
                        child: Text(actionText!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onClose != null) CustomBackButton(onClose: onClose),
          ],
        ),
      ),
    );
  }
}
