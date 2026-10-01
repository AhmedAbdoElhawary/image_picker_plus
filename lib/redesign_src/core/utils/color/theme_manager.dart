import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/color_manager.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_adaptation.dart';

enum ThemeEnum {
  primaryColor,
  focusColor,
  hintColor,
  whiteD1Color,
  whiteD2Color,
  whiteD1And5Color,
  whiteD05Color,
  solidWhiteD3Color,
  whiteD3Color,
  whiteD4Color,
  whiteD5Color,
  whiteD7Color,
  whiteColor,
  transparentColor,
  blackColor,
  cropGreyOp25,
  solidWhiteOp80Color,
  solidWhiteOp40Color,
  greyColor,
  fillGreyColor,
  darkGreyColor,
  trendsRankingColor,
  hoverColor,
  blackOp50,
  bottomSheetColor,
  blackBottomSheetColor,
  staticBlackHoverColor,
  staticBlackBlackL2Color,
  blueColor,
  darkBlueColor,
  lightBlueColor,
  greenColor,
  yellowColor,
  redColor,
  blackRedColor,
  orangeColor,
  greyButtonTextColor,
  d9Color,
  iconColor
}

extension ThemeExtension on BuildContext {
  Map<ThemeEnum, Color> get _colors {
    final isLight = ThemeAdaptation().isLight;

    final primaryLight = isLight ? ColorManager.whiteD2 : ColorManager.blackL2;
    final hoverColor = isLight ? ColorManager.blackOp60 : ColorManager.whiteOp60;

    /// what ever dark or light. Maybe if we have multiple themes, it will save a lot of time.
    return {
      ThemeEnum.primaryColor: isLight ? ColorManager.white : ColorManager.black,
      ThemeEnum.whiteColor: ColorManager.white,
      ThemeEnum.focusColor: isLight ? ColorManager.black : ColorManager.white,
      ThemeEnum.iconColor: isLight ? ColorManager.black : ColorManager.white,
      ThemeEnum.blackColor: ColorManager.black,
      ThemeEnum.staticBlackHoverColor: ColorManager.whiteOp60,
      ThemeEnum.staticBlackBlackL2Color: ColorManager.blackL2,

      /// ---------------->

      // it's not wrong all of them hover color
      ThemeEnum.hintColor: hoverColor,
      ThemeEnum.hoverColor: hoverColor,
      ThemeEnum.darkGreyColor: hoverColor,
      ThemeEnum.greyColor: hoverColor,
      ThemeEnum.trendsRankingColor: hoverColor,
      ThemeEnum.fillGreyColor: hoverColor,
      ThemeEnum.blackOp50: hoverColor,

      /// ---------------->

      ThemeEnum.whiteD1Color: isLight ? ColorManager.whiteF5 : ColorManager.blackL4,
      ThemeEnum.whiteD2Color: primaryLight,
      ThemeEnum.solidWhiteD3Color: ColorManager.whiteD3,

      ThemeEnum.whiteD3Color: isLight ? ColorManager.whiteD3 : ColorManager.blackL3,
      ThemeEnum.whiteD4Color: isLight ? ColorManager.whiteD4 : ColorManager.blackL4,
      ThemeEnum.whiteD1And5Color: isLight ? ColorManager.whiteD1A : ColorManager.blackL2A,
      ThemeEnum.whiteD05Color: isLight ? ColorManager.whiteF5 : ColorManager.blackL2A,
      ThemeEnum.whiteD5Color: isLight ? ColorManager.whiteD5 : ColorManager.blackL5,
      ThemeEnum.whiteD7Color: isLight ? ColorManager.whiteD7 : ColorManager.blackL6,
      ThemeEnum.d9Color: isLight ? ColorManager.whiteD9 : ColorManager.greyD9,

      ThemeEnum.bottomSheetColor: isLight ? ColorManager.whiteF5 : ColorManager.blackL4,
      ThemeEnum.blackBottomSheetColor: ColorManager.blackL4,

      /// ---------------->

      ThemeEnum.transparentColor: ColorManager.transparent,

      ThemeEnum.cropGreyOp25: isLight ? ColorManager.cropWhiteGreyOp25 : ColorManager.cropBlackGreyOp25,

      ThemeEnum.solidWhiteOp80Color: ColorManager.whiteOp80,
      ThemeEnum.solidWhiteOp40Color: ColorManager.whiteOp40,

      ///
      ThemeEnum.blueColor: ColorManager.blue,
      ThemeEnum.darkBlueColor: ColorManager.darkBlue,
      ThemeEnum.lightBlueColor: ColorManager.lightBlue,
      ThemeEnum.greenColor: ColorManager.green,
      ThemeEnum.redColor: ColorManager.red,
      ThemeEnum.blackRedColor: ColorManager.blackRed,
      ThemeEnum.orangeColor: ColorManager.orange,
      ThemeEnum.yellowColor: ColorManager.yellow,

      //
      ThemeEnum.greyButtonTextColor: isLight ? ColorManager.white : ColorManager.white,
    };
  }

  Color getColor(ThemeEnum color) => _colors[color] ?? Theme.of(this).primaryColor;
}
