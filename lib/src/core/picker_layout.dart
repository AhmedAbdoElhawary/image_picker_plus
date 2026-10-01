import 'package:flutter/widgets.dart';

class PickerLayout {
  final int columns;

  /// preview next to the grid instead of above it.
  final bool previewBeside;

  const PickerLayout._(this.columns, this.previewBeside);

  static const double gap = 2;
  static const double padding = 16;
  static const double radius = 14;
  static const double minTouch = 48;

  factory PickerLayout.of(BuildContext context) => PickerLayout.forSize(MediaQuery.sizeOf(context));

  factory PickerLayout.forSize(Size size) {
    final width = size.width;
    final columns = width < 600 ? 4 : (width < 1024 ? 6 : 8);
    final beside = width >= 1024 || (width >= 600 && width > size.height);
    return PickerLayout._(columns, beside);
  }
}
