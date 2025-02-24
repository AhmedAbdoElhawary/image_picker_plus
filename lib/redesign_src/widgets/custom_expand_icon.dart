import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_manager.dart';

class CustomExpandIcon extends StatelessWidget {
  const CustomExpandIcon({
    required this.onTap,
    this.isExpanded = false,
    super.key,
  });
  final VoidCallback onTap;
  final bool isExpanded;
  @override
  Widget build(BuildContext context) {
    return IconCircleAvatar(
      onTap: onTap,
      child: Transform.rotate(
        angle: 51,
        child: isExpanded
            ? Icon(
                Icons.unfold_less_rounded,
                color: context.getColor(ThemeEnum.primaryColor),
                size: 22.r,
              )
            : Icon(
                Icons.unfold_more_rounded,
                color:context.getColor(ThemeEnum.primaryColor),
                size: 22.r,
              ),
      ),
    );
  }
}

class IconCircleAvatar extends StatelessWidget {
  const IconCircleAvatar({
    this.withInternalPadding = false,
    required this.onTap,
    required this.child,
    super.key,
  });
  final VoidCallback onTap;
  final Widget child;
  final bool withInternalPadding;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.r),
      child: InkWell(
        radius: 50,
        onTap: onTap,
        child: CircleAvatar(
          radius: 18.r,
          backgroundColor: context.getColor(ThemeEnum.blackOp50),
          child: Padding(
            padding: EdgeInsets.all(withInternalPadding ? 4.r : 0),
            child: child,
          ),
        ),
      ),
    );
  }
}
