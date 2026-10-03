import 'package:flutter/widgets.dart';

class PickerLayout {
  final int columns;

  /// preview next to the grid instead of above it.
  final bool previewBeside;

  const PickerLayout._(this.columns, this.previewBeside);

  static const double gap = 1;
  static const double padding = 16;
  static const double ratioButtonBottomPadding = 5;
  static const double radius = 14;
  static const double minTouch = 48;
  static const double minButtonTouchHeight = 30;
  static const double pickerTabsHeight = 52;

  /// the edit page on web and desktop is a card from this width up.
  static const double cardBreakpoint = 600;
  static const double cardMaxWidth = 960;
  static const double cardMaxHeight = 900;
  static const double cardMargin = 24;

  factory PickerLayout.of(BuildContext context) => PickerLayout.forSize(MediaQuery.sizeOf(context));

  factory PickerLayout.forSize(Size size) {
    final width = size.width;
    final columns = width < 600 ? 4 : (width < 1024 ? 6 : 8);
    final beside = width >= 1024 || (width >= 600 && width > size.height);
    return PickerLayout._(columns, beside);
  }
}
