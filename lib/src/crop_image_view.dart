import 'dart:io';
import 'package:custom_gallery_display/src/custom_expand_icon.dart';
import 'package:custom_gallery_display/src/entities/app_theme.dart';
import 'package:custom_gallery_display/src/custom_packages/crop_image/crop_image.dart';
import 'package:flutter/material.dart';

class CropImageView extends StatefulWidget {
  final ValueNotifier<GlobalKey<CustomCropState>> cropKey;
  final ValueNotifier<List<int>> indexOfSelectedImages;
  final ValueNotifier<List<double>> scaleOfCropsKeys;
  final ValueNotifier<List<Rect?>> areaOfCropsKeys;
  final ValueNotifier<List<File>> multiSelectedImage;

  final ValueNotifier<bool> multiSelectionMode;
  final ValueNotifier<bool> expandImage;
  final ValueNotifier<double> expandHeight;
  final ValueNotifier<bool> expandImageView;

  /// To avoid lag when you interacting with image when it expanded
  final ValueNotifier<bool> enableVerticalTapping;
  final ValueNotifier<File?> selectedImage;
  final VoidCallback clearMultiImages;

  final AppTheme appTheme;
  final ValueNotifier<bool> noDuration;
  final Color whiteColor;
  final double? topPosition;

  const CropImageView({
    Key? key,
    required this.indexOfSelectedImages,
    required this.cropKey,
    required this.multiSelectedImage,
    required this.scaleOfCropsKeys,
    required this.areaOfCropsKeys,
    required this.multiSelectionMode,
    required this.expandImage,
    required this.expandHeight,
    required this.clearMultiImages,
    required this.expandImageView,
    required this.enableVerticalTapping,
    required this.selectedImage,
    required this.appTheme,
    required this.noDuration,
    required this.whiteColor,
    this.topPosition,
  }) : super(key: key);

  @override
  State<CropImageView> createState() => _CropImageViewState();
}

class _CropImageViewState extends State<CropImageView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.enableVerticalTapping,
      builder: (context, bool enableTappingValue, child) => GestureDetector(
        onVerticalDragUpdate: enableTappingValue && widget.topPosition != null
            ? (details) {
                widget.expandImageView.value = true;
                widget.expandHeight.value = details.globalPosition.dy - 56;
                setState(() => widget.noDuration.value = true);
              }
            : null,
        onVerticalDragEnd: enableTappingValue && widget.topPosition != null
            ? (details) {
                widget.expandHeight.value =
                    widget.expandHeight.value > 260 ? 360 : 0;
                if (widget.topPosition == -360) {
                  widget.enableVerticalTapping.value = true;
                }
                if (widget.topPosition == 0) {
                  widget.enableVerticalTapping.value = false;
                }
                setState(() => widget.noDuration.value = false);
              }
            : null,
        child: ValueListenableBuilder(
          valueListenable: widget.selectedImage,
          builder: (context, File? selectedImageValue, child) {
            if (selectedImageValue != null) {
              return showSelectedImage(context, selectedImageValue);
            } else {
              return Container(key: GlobalKey(debugLabel: "do not have"));
            }
          },
        ),
      ),
    );
  }

  Container showSelectedImage(BuildContext context, File selectedImageValue) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      key: GlobalKey(debugLabel: "have image"),
      color: widget.whiteColor,
      height: 360,
      width: width,
      child: ValueListenableBuilder(
        valueListenable: widget.multiSelectionMode,
        builder: (context, bool multiSelectionModeValue, child) => Stack(
          children: [
            ValueListenableBuilder(
              valueListenable: widget.expandImage,
              builder: (context, bool expandImageValue, child) =>
                  cropImageWidget(selectedImageValue, expandImageValue),
            ),
            if (widget.topPosition != null) ...[
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (multiSelectionModeValue) widget.clearMultiImages();

                        widget.multiSelectionMode.value =
                            !multiSelectionModeValue;
                      });
                    },
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: multiSelectionModeValue
                            ? Colors.blue
                            : const Color.fromARGB(165, 58, 58, 58),
                        border: Border.all(
                          color: const Color.fromARGB(45, 250, 250, 250),
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.copy, color: Colors.white, size: 17),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.expandImage.value = !widget.expandImage.value;
                    });
                  },
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(165, 58, 58, 58),
                      border: Border.all(
                        color: const Color.fromARGB(45, 250, 250, 250),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CustomExpandIcon(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cropImageWidget(File selectedImageValue, bool expandImageValue) {
    GlobalKey<CustomCropState> cropKey = widget.cropKey.value;
    return CustomCrop.file(
      selectedImageValue,
      key: cropKey,
      paintColor: widget.appTheme.primaryColor,
      aspectRatio: expandImageValue ? 6 / 8 : 1.0,
    );
  }
}
