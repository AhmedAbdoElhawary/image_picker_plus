import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_manager.dart';

class CustomCircularProgress extends StatelessWidget {
  final ThemeEnum? color;
  final double size;
  const CustomCircularProgress({this.color, this.size = 20, super.key});

  @override
  Widget build(BuildContext context) {
    bool isThatAndroid = defaultTargetPlatform == TargetPlatform.android;
    final color = this.color;
    final tColor = color == null ? Theme.of(context).focusColor : context.getColor(color);

    return isThatAndroid
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 0.75,
                child: SizedBox(
                  width: size.r,
                  height: size.r,
                  child: CircularProgressIndicator(strokeWidth: 3.r, color: tColor),
                ),
              ),
            ],
          )
        : CupertinoActivityIndicator(color: tColor, radius: 9.r, animating: true);
  }
}
