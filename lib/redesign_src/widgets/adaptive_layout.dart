import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart';

class SliverAdaptivePaddingLayout extends StatelessWidget {
  const SliverAdaptivePaddingLayout({
    required this.sliver,
    this.largeDivideNum = 2.3,
    super.key,
  });
  final Widget sliver;
  final double largeDivideNum;
  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.crossAxisExtent < ScreenSizeHelper().maxWidthAllowed
            ? 0.0
            : ((constraints.crossAxisExtent - ScreenSizeHelper().defaultSize.width) / largeDivideNum);

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding < 0 ? 0 : horizontalPadding),
          sliver: sliver,
        );
      },
    );
  }
}

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.child});
  final Widget Function(bool isLargeScreen) child;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = ScreenSizeHelper().isTablet;
        return child(isLargeScreen);
      },
    );
  }
}
