import 'package:flutter/material.dart';

/// [ColorManager]
/// colorD means that get dark version from the color for example:
/// greyD2 means that get version 2 darker from grey.
/// "less darker D1 < D2 < D4 < D7 < D9 more darker"
/// ------------------------>
/// colorL means that get light version from the color for example:
/// blackL4 means that get version 4 lighter from dark.
/// "less lighter L1 < L2 < L3 < L5 < L8 more lighter"
/// ------------------------>
/// colorOp means that get less opacity version from the main color for example:
/// blackT1 means that get the same main color "black" but with less opacity.
/// opacity  for main black:
/// black => 100%
/// blackOp90 => 90%
/// blackOp80 => 80%
/// blackOp70 => 70%
/// blackOp60 => 60%
/// blackOp50 => 50%
/// blackOp40 => 40%
/// blackOp30 => 30%
/// blackOp20 => 20%
/// blackOp10 => 10%

abstract final class ColorManager {
  static const Color transparent = Colors.transparent;
  static const Color transparentWhite = Color.fromRGBO(255, 255, 255, 0.48627450980392156);
  static const Color whiteOp10 = Color.fromRGBO(255, 255, 255, .1);
  static const Color whiteOp20 = Color.fromRGBO(255, 255, 255, .2);
  static const Color whiteOp30 = Color.fromRGBO(255, 255, 255, .3);
  static const Color whiteOp40 = Color.fromRGBO(255, 255, 255, .4);
  static const Color whiteOp50 = Color.fromRGBO(255, 255, 255, .5);
  static const Color whiteOp60 = Color.fromRGBO(160, 166, 172, 1);

  static const Color whiteOp70 = Color.fromRGBO(255, 255, 255, .7);
  static const Color whiteOp80 = Color.fromRGBO(255, 255, 255, .8);
  static const Color whiteOp90 = Color.fromRGBO(255, 255, 255, .9);
  static const Color whiteOp98 = Color.fromRGBO(255, 255, 255, .98);
  static const Color white = Color.fromRGBO(255, 255, 255, 1);
  static const Color whiteF5 = Color.fromRGBO(250, 250, 250, 1);
  static const Color whiteD1 = Color.fromRGBO(245, 245, 245, 1);
  static const Color whiteD1A = Color.fromRGBO(241, 241, 241, 0.4);
  static const Color whiteD2 = Color.fromRGBO(240, 240, 240, 1);
  static const Color whiteD3 = Color.fromRGBO(235, 235, 235, 1);
  static const Color whiteD4 = Color.fromRGBO(225, 225, 225, 1);
  static const Color whiteD5 = Color.fromRGBO(215, 215, 215, 1);
  static const Color whiteD6 = Color.fromRGBO(205, 205, 205, 1);
  static const Color whiteD7 = Color.fromRGBO(195, 195, 195, 1);
  static const Color whiteD8 = Color.fromRGBO(185, 185, 185, 1);
  static const Color whiteD9 = Color.fromRGBO(175, 175, 175, 1);
  static const Color whiteD10 = Color.fromRGBO(165, 165, 165, 1);

  // for #396 #397
  static const Color cropWhiteGreyOp25 = Color.fromRGBO(183, 183, 183, 0.5);
  static const Color cropBlackGreyOp25 = Color.fromRGBO(44, 44, 44, 0.5019607843137255);
  //

  static const Color grey = Color.fromRGBO(155, 155, 155, 1);
  static const Color greyOp70 = Color.fromRGBO(155, 155, 155, 0.84);
  static const Color greyD1 = Color.fromRGBO(145, 145, 145, 1);
  static const Color greyD2 = Color.fromRGBO(135, 135, 135, 1);
  static const Color greyD3 = Color.fromRGBO(125, 125, 125, 1);
  static const Color greyD4 = Color.fromRGBO(115, 115, 115, 1);
  static const Color greyD5 = Color.fromRGBO(105, 105, 105, 1);
  static const Color greyD6 = Color.fromRGBO(95, 95, 95, 1);
  static const Color greyD7 = Color.fromRGBO(85, 85, 85, 1);
  static const Color greyD8 = Color.fromRGBO(75, 75, 75, 1);
  static const Color greyD9 = Color.fromRGBO(65, 65, 65, 1);

  static const Color blackL6 = Color.fromRGBO(37, 40, 55, 1);
  static const Color blackL5 = Color.fromRGBO(37, 40, 50, 1);
  static const Color blackL4 = Color.fromRGBO(37, 40, 45, 1);
  static const Color blackL3 = Color.fromRGBO(37, 40, 45, 1);
  static const Color blackL3A = Color.fromRGBO(37, 40, 45, 0.9);
  static const Color blackL2 = Color.fromRGBO(22, 25, 30, 1);
  static const Color blackL2A = Color.fromRGBO(18, 21, 26, 0.7);
  static const Color blackL1 = Color.fromRGBO(17, 20, 25, 1);
  static const Color black = Color.fromRGBO(12, 16, 21, 1);
  static const Color realBlack = Color.fromRGBO(0, 0, 0, 1.0);

  static const Color blackOp98 = Color.fromRGBO(12, 15, 20, 0.98);
  static const Color blackOp90 = Color.fromRGBO(12, 15, 20, 0.9);
  static const Color blackOp80 = Color.fromRGBO(12, 15, 20, 0.8);
  static const Color blackOp70 = Color.fromRGBO(12, 15, 20, 0.7);
  static const Color blackOp60 = Color.fromRGBO(117, 122, 128, 1);
  static const Color blackOp50 = Color.fromRGBO(12, 15, 20, 0.5);
  static const Color blackOp40 = Color.fromRGBO(12, 15, 20, 0.4);
  static const Color blackOp30 = Color.fromRGBO(12, 15, 20, 0.3);
  static const Color blackOp20 = Color.fromRGBO(12, 15, 20, 0.2);
  static const Color blackOp10 = Color.fromRGBO(12, 15, 20, 0.1);

  static const Color toastBlack = Color.fromRGBO(215, 215, 215, 0.6);
  static const Color toastWhite = Color.fromRGBO(255, 250, 250, 0.4);

  /// ------------------------------------------>

  static const Color tagPin = Color(0xFF282B2F);
  static const Color blue = Color.fromRGBO(41, 157, 250, 1.0);
  static const Color darkBlue1 = Color.fromRGBO(23, 154, 255, 1.0);
  static const Color darkBlue = Color.fromRGBO(7, 114, 199, 1.0);
  static const Color lightBlue = Color.fromRGBO(177, 221, 255, 1.0);
  static const Color lightBlueM2 = Color.fromRGBO(209, 234, 255, 1.0);
  static const Color lightBlueWhiteD1 = Color.fromRGBO(243, 243, 246, 1.0);
  static const Color blackBlue = Color.fromRGBO(0, 0, 5, 1.0);
  static const Color green = Color.fromRGBO(25, 189, 98, 1.0);
  static const Color purple = Color.fromRGBO(160, 4, 238, 1);
  static const Color purple2 = Color.fromRGBO(198, 0, 229, 1.0);
  static const Color red = Color.fromRGBO(210, 41, 11, 1.0);
  static const Color red2 = Color.fromRGBO(241, 83, 47, 1.0);
  static const Color blackRed = Color.fromARGB(255, 182, 14, 14);
  static const Color orange = Color.fromRGBO(253, 160, 7, 1.0);
  static const Color teal = Color.fromRGBO(35, 133, 100, 1);
  static const Color redAccent = Color.fromRGBO(236, 91, 98, 1);
  static const Color yellow = Color.fromRGBO(246, 209, 11, 1.0);
  static const Color lightYellow = Color.fromARGB(219, 255, 240, 27);
  static const Color light2Yellow = Color.fromARGB(255, 255, 217, 27);
}
