import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart';
import 'package:image_picker_plus/redesign_src/widgets/custom_circle_progress.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_manager.dart';
import 'package:image_picker_plus/redesign_src/core/utils/context_extension.dart';
import 'package:image_picker_plus/redesign_src/core/utils/string_manager.dart';
import 'package:image_picker_plus/redesign_src/widgets/adaptive_layout.dart';

import 'main_parent_context.dart';

typedef CloseLoadingScreen = bool Function();
typedef UpdateLoadingScreen = bool Function(String text);

@immutable
class LoadingScreenController {
  final CloseLoadingScreen close;

  const LoadingScreenController({required this.close});
}

class GeneralLoadingScreen {
  GeneralLoadingScreen._shareInstance();
  static final GeneralLoadingScreen _shared = GeneralLoadingScreen._shareInstance();
  factory GeneralLoadingScreen.getInstance() => _shared;

  LoadingScreenController? _controller;

  void showAlertDialog(
    BuildContext context, {
    ThemeEnum? backgroundColor,
    String text = StringsManager.loading,
    bool userLocalContext = false,
    bool withLoadingIndicator = true,
  }) {
    hide();
    _controller = _showOverlay(
      context,
      userLocalContext: userLocalContext,
      backgroundColor: backgroundColor,
      builder: (p0) => _AlertDialog(
        text: text,
        withLoadingIndicator: withLoadingIndicator,
      ),
    );
  }

  void hide() {
    _controller?.close();
    _controller = null;
  }

  LoadingScreenController? _showOverlay(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
    ThemeEnum? backgroundColor,
    bool userLocalContext = false,
  }) {
    BuildContext ctx = ParentContext().getContext ?? context;
    if (userLocalContext && context.mounted) ctx = context;

    final state = Overlay.of(ctx);
    final color = backgroundColor == null ? null : ctx.getColor(backgroundColor);

    final theme = color ?? Colors.black54;

    context.unFocusKeyboard();

    final overlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: theme,
          child: builder(context),
        );
      },
    );

    state.insert(overlay);

    return LoadingScreenController(
      close: () {
        overlay.remove();
        return true;
      },
    );
  }
}

class _AlertDialog extends StatelessWidget {
  const _AlertDialog({
    this.withLoadingIndicator = true,
    this.text = StringsManager.loading,
  });
  final bool withLoadingIndicator;
  final String text;
  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: (isLargeScreen) {
        final width = isLargeScreen ? 450 : MediaQuery.sizeOf(context).width;

        return AlertDialog(
          shape: Border.all(
            color: context.getColor(ThemeEnum.primaryColor).withValues(alpha: 0.2),
          ),
          backgroundColor: context.getColor(ThemeEnum.bottomSheetColor),
          shadowColor: context.getColor(ThemeEnum.whiteD7Color),
          insetPadding: EdgeInsets.all(width * .23),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.r),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (withLoadingIndicator) ...[
                    CustomCircularProgress(),
                    SizedBox(width: 10.r),
                  ],
                  Text(text, style: TextStyle(fontSize: 16.r))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
