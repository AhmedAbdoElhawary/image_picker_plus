import 'dart:io' show File;
import 'package:flutter/material.dart' show BuildContext;
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/redesign_src/core/utils/string_manager.dart';
import 'package:image_picker_plus/redesign_src/widgets/crop_image.dart';

class EditImagePageBaseParameters {
  final List<File> editedImagesFiles;
  final List<File> originalImagesFiles;
  final List<int> selectedFilersIndexes;
  final List<int> selectedRotation;
  final double aspectRatio;
  final String tempCacheSessionUUid;

  const EditImagePageBaseParameters({
    required this.editedImagesFiles,
    required this.originalImagesFiles,
    required this.selectedFilersIndexes,
    required this.selectedRotation,
    required this.aspectRatio,
    required this.tempCacheSessionUUid,
  });
}

class EditImagePageParameters extends EditImagePageBaseParameters {
  double? resizeWidth;
  double? resizeHeight;
  List<File> originSelectedImage;
  List<File> croppedSelectedImage;
  List<img.Image> originSelectedImg;
  int? maxImageSelected;
  final CropEditImageType type;
  void Function(BuildContext context, EditImagePageBaseParameters? par) onImageEditedFinish;
  final String nextText;
  final List<double> allowedAspectRatios;
  EditImagePageParameters({
    this.resizeWidth,
    this.resizeHeight,
    this.nextText = StringsManager.done,
    required this.originSelectedImg,
    required this.originSelectedImage,
    required this.croppedSelectedImage,

    /// TODO: check if there is single value in aspect ratio (disable expand icon)
    /// and if empty don't apply aspect ratio at all
    this.allowedAspectRatios = const [1.0, 4 / 5],
    required super.selectedFilersIndexes,
    required super.selectedRotation,
    required super.tempCacheSessionUUid,
    super.aspectRatio = 1,
    required this.onImageEditedFinish,
    required this.maxImageSelected,
    this.type = CropEditImageType.normal,
  }) : super(editedImagesFiles: croppedSelectedImage, originalImagesFiles: originSelectedImage);
}
