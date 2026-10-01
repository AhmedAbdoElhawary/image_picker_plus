import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  void unFocusKeyboard() {
    try {
      if (mounted) FocusScope.of(this).unfocus();
    } catch (e) {
      //
    }
  }

  void reqKeyboardFocus(FocusNode textFocusNote) {
    try {
      if (mounted) FocusScope.of(this).requestFocus(textFocusNote);
    } catch (e) {
      //
    }
  }

  bool canPop() => Navigator.of(this).canPop();

  void pop({dynamic result}) {
    try {
      unFocusKeyboard();

      if (canPop()) return Navigator.of(this).pop(result);
    } catch (e) {
      debugPrint("something wrong when pop page: $e");
    }
  }

  Future push(Widget widget) async {
    try {
      unFocusKeyboard();

      return Navigator.of(this).push(
        MaterialPageRoute(
          builder: (context) {
            return widget;
          },
        ),
      );
    } catch (e) {
      debugPrint("something wrong when pop page: $e");
    }
  }
}
