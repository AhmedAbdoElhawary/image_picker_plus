import 'package:flutter/material.dart';

class ScreenSizeHelper {
  static final ScreenSizeHelper _instance = ScreenSizeHelper._internal();
  factory ScreenSizeHelper() => _instance;
  ScreenSizeHelper._internal();

  Size? _screenSize;

  Size get getScreenSize => _screenSize!;

  bool get isTablet => getScreenSize.width > 600;

  void initializeScreenSize(BuildContext context) {
    _screenSize = MediaQuery.sizeOf(context);
  }
}

extension SizeHelper on double {
  double get r {
    if (ScreenSizeHelper().isTablet) {
      final ratio =
          ScreenSizeHelper().getScreenSize.shortestSide / ScreenSizeHelper().getScreenSize.longestSide;
      return this * ratio;
    }
    return this;
  }
}

extension SizeIntHelper on int {
  double get r => toDouble().r;
}
