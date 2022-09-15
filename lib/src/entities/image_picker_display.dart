import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:flutter/material.dart';

/// [GalleryDisplaySettings] When you make ImageSource from the camera these settings will be disabled because they belong to the gallery.
class GalleryDisplaySettings {
  AppTheme? appTheme;
  TabsTexts? tabsTexts;
  SliverGridDelegateWithFixedCrossAxisCount gridDelegate;
  bool showImagePreview;
  AsyncValueSetter<SelectedImagesDetails>? sendRequestFunction;

  /// If [cropImage] true [showImagePreview] will be true
  /// Right now this package not support crop video
  bool cropImage;

  GalleryDisplaySettings({
    this.appTheme,
    this.sendRequestFunction,
    this.tabsTexts,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 1.7, mainAxisSpacing: 1.5),
    this.showImagePreview = false,
    this.cropImage = false,
  });
}
