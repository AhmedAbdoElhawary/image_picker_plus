import 'dart:io';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:image_picker_plus/src/camera_display.dart';
import 'package:image_picker_plus/src/images_view_page.dart';
import 'package:image_picker_plus/src/utilities/enum.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CustomImagePicker extends StatefulWidget {
  final ImageSource source;
  final bool multiSelection;
  final GalleryDisplaySettings? galleryDisplaySettings;
  final PickerSource pickerSource;

  const CustomImagePicker({
    required this.source,
    required this.multiSelection,
    required this.galleryDisplaySettings,
    required this.pickerSource,
    super.key,
  });

  @override
  CustomImagePickerState createState() => CustomImagePickerState();
}

class CustomImagePickerState extends State<CustomImagePicker>
    with TickerProviderStateMixin {
  final pageController = ValueNotifier(PageController());
  final clearVideoRecord = ValueNotifier(false);
  final redDeleteText = ValueNotifier(false);
  final selectedPage = ValueNotifier(SelectedPage.left);
  late ValueNotifier<void> initializeControllerFuture;
  ValueNotifier<List<File>> multiSelectedImage = ValueNotifier([]);
  late ValueNotifier<CameraController> controller;
  final multiSelectionMode = ValueNotifier(false);
  final showDeleteText = ValueNotifier(false);
  final selectedVideo = ValueNotifier(false);
  ValueNotifier<File?> selectedCameraImage = ValueNotifier(null);
  late bool cropImage;
  late AppTheme appTheme;
  late TabsTexts tapsNames;
  late bool showImagePreview;

  ValueNotifier<List<CameraDescription>>? cameras;
  late Color whiteColor;
  late Color blackColor;
  late GalleryDisplaySettings imagePickerDisplay;

  late bool enableCamera;
  late bool enableVideo;

  late bool showInternalVideos;
  late bool showInternalImages;
  late SliverGridDelegateWithFixedCrossAxisCount gridDelegate;

  @override
  void initState() {
    _initializeVariables();
    _initializeCamera(0, true);
    super.initState();
  }

  _initializeVariables() {
    imagePickerDisplay =
        widget.galleryDisplaySettings ?? GalleryDisplaySettings();
    appTheme = imagePickerDisplay.appTheme ?? AppTheme();
    tapsNames = imagePickerDisplay.tabsTexts ?? TabsTexts();
    cropImage = imagePickerDisplay.cropImage;
    showImagePreview = cropImage || imagePickerDisplay.showImagePreview;
    gridDelegate = imagePickerDisplay.gridDelegate;

    showInternalImages = widget.pickerSource != PickerSource.video;
    showInternalVideos = widget.pickerSource != PickerSource.image;

    bool notGallery = widget.source != ImageSource.gallery;

    enableCamera = showInternalImages && notGallery;
    enableVideo = showInternalVideos && notGallery;
    whiteColor = appTheme.primaryColor;
    blackColor = appTheme.focusColor;
  }

  Future<void> _initializeCamera(int index, bool checkCamera) async {
    cameras = ValueNotifier(await availableCameras());
    if (mounted) {
      controller = ValueNotifier(CameraController(
        cameras!.value[index],
        ResolutionPreset.high,
        enableAudio: true,
      ));
      initializeControllerFuture =
          ValueNotifier(await controller.value.initialize());
      setState(() {});
    }
  }

  @override
  void dispose() {
    // initializeControllerFuture.dispose();
    multiSelectionMode.dispose();
    showDeleteText.dispose();
    selectedVideo.dispose();
    selectedPage.dispose();
    // selectedCameraImage.dispose();
    pageController.dispose();
    // clearVideoRecord.dispose();
    // redDeleteText.dispose();
    // cameras!.dispose();
    // multiSelectedImage.dispose();
    // controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return defaultTabController();
  }

  Widget tapBarMessage(bool isThatDeleteText) {
    Color deleteColor = redDeleteText.value ? Colors.red : appTheme.focusColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: GestureDetector(
          onTap: () async {
            if (isThatDeleteText) {
              setState(() {
                if (!redDeleteText.value) {
                  redDeleteText.value = true;
                } else {
                  selectedCameraImage.value = null;
                  clearVideoRecord.value = true;
                  showDeleteText.value = false;
                  redDeleteText.value = false;
                }
              });
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isThatDeleteText)
                Icon(Icons.arrow_back_ios_rounded,
                    color: deleteColor, size: 15),
              Text(
                  isThatDeleteText
                      ? tapsNames.deletingText
                      : tapsNames.limitingText,
                  style: TextStyle(
                      fontSize: 14,
                      color: deleteColor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget clearSelectedImages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: GestureDetector(
          onTap: () async {
            setState(() {
              multiSelectionMode.value = !multiSelectionMode.value;
              if (!multiSelectionMode.value) {
                multiSelectedImage.value.clear();
              }
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(tapsNames.clearImagesText,
                  style: TextStyle(
                      fontSize: 14,
                      color: appTheme.focusColor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  replacingDeleteWidget(bool showDeleteText) {
    this.showDeleteText.value = showDeleteText;
  }

  moveToVideo() {
    setState(() {
      selectedPage.value = SelectedPage.right;
      selectedVideo.value = true;
    });
  }

  DefaultTabController defaultTabController() {
    return DefaultTabController(
        length: 2, child: Material(color: whiteColor, child: safeArea()));
  }

  SafeArea safeArea() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ValueListenableBuilder(
              valueListenable: pageController,
              builder: (context, PageController pageControllerValue, child) =>
                  PageView(
                controller: pageControllerValue,
                dragStartBehavior: DragStartBehavior.start,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  imagesViewPage(),
                  if (enableCamera || enableVideo) cameraPage(),
                ],
              ),
            ),
          ),
          if (multiSelectedImage.value.length < 10) ...[
            if (enableVideo || enableCamera)
              ValueListenableBuilder(
                valueListenable: multiSelectionMode,
                builder: (context, bool multiSelectionModeValue, child) {
                  if (!showImagePreview) {
                    if (multiSelectionModeValue) {
                      return clearSelectedImages();
                    } else {
                      return buildTabBar();
                    }
                  } else {
                    return Visibility(
                      visible: !multiSelectionModeValue,
                      child: buildTabBar(),
                    );
                  }
                },
              )
          ] else ...[
            tapBarMessage(false)
          ],
        ],
      ),
    );
  }

  ValueListenableBuilder<bool> cameraPage() {
    return ValueListenableBuilder(
      valueListenable: selectedVideo,
      builder: (context, bool selectedVideoValue, child) => CustomCameraDisplay(
        controller: controller,
        appTheme: appTheme,
        selectedCameraImage: selectedCameraImage,
        tapsNames: tapsNames,
        cameras: cameras!,
        enableCamera: enableCamera,
        onNewCameraSelected: _initializeCamera,
        enableVideo: enableVideo,
        initializeControllerFuture: initializeControllerFuture,
        replacingTabBar: replacingDeleteWidget,
        clearVideoRecord: clearVideoRecord,
        redDeleteText: redDeleteText,
        moveToVideoScreen: moveToVideo,
        selectedVideo: selectedVideoValue,
      ),
    );
  }

  void clearMultiImages() {
    setState(() {
      multiSelectedImage.value.clear();
      multiSelectionMode.value = false;
    });
  }

  ImagesViewPage imagesViewPage() {
    return ImagesViewPage(
      appTheme: appTheme,
      clearMultiImages: clearMultiImages,
      gridDelegate: gridDelegate,
      multiSelectionMode: multiSelectionMode,
      blackColor: blackColor,
      showImagePreview: showImagePreview,
      tabsTexts: tapsNames,
      multiSelectedImage: multiSelectedImage,
      whiteColor: whiteColor,
      cropImage: cropImage,
      multiSelection: widget.multiSelection,
      showInternalVideos: showInternalVideos,
      showInternalImages: showInternalImages,
    );
  }

  ValueListenableBuilder<bool> buildTabBar() {
    return ValueListenableBuilder(
      valueListenable: showDeleteText,
      builder: (context, bool showDeleteTextValue, child) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInOutQuart,
          child: showDeleteTextValue ? tapBarMessage(true) : tabBar()),
    );
  }

  Widget tabBar() {
    double widthOfScreen = MediaQuery.of(context).size.width;
    bool cameraAndVideoEnabled = enableCamera && enableVideo;
    int divideNumber = cameraAndVideoEnabled ? 3 : 2;
    double widthOfTab = widthOfScreen / divideNumber;
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        ValueListenableBuilder(
          valueListenable: selectedPage,
          builder: (context, SelectedPage selectedPageValue, child) {
            Color photoColor = selectedPageValue == SelectedPage.center
                ? blackColor
                : Colors.grey;
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      centerPage(numPage: 0, selectedPage: SelectedPage.left);
                    });
                  },
                  child: SizedBox(
                    width: widthOfTab,
                    height: 40,
                    child: Center(
                      child: Text(tapsNames.galleryText,
                          style: TextStyle(
                              color: selectedPageValue == SelectedPage.left
                                  ? blackColor
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                if (enableCamera) photoTabBar(widthOfTab, photoColor),
                if (enableVideo) videoTabBar(widthOfTab),
              ],
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: selectedPage,
          builder: (context, SelectedPage selectedPageValue, child) =>
              AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuad,
            right: (selectedPageValue == SelectedPage.center
                ? widthOfTab
                : (selectedPageValue == SelectedPage.right
                    ? 0
                    : (divideNumber == 2 ? widthOfTab : widthOfScreen / 1.5))),
            child: Container(height: 1, width: widthOfTab, color: blackColor),
          ),
        ),
      ],
    );
  }

  GestureDetector photoTabBar(double widthOfTab, Color textColor) {
    return GestureDetector(
      onTap: () => centerPage(numPage: 1, selectedPage: SelectedPage.center),
      child: SizedBox(
        width: widthOfTab,
        height: 40,
        child: Center(
          child: Text(tapsNames.photoText,
              style: TextStyle(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  centerPage({required int numPage, required SelectedPage selectedPage}) {
    setState(() {
      this.selectedPage.value = selectedPage;
      pageController.value.animateToPage(numPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuad);
      selectedVideo.value = false;
    });
  }

  GestureDetector videoTabBar(double widthOfTab) {
    return GestureDetector(
      onTap: () {
        setState(() {
          pageController.value.animateToPage(1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutQuad);
          selectedPage.value = SelectedPage.right;
          selectedVideo.value = true;
        });
      },
      child: SizedBox(
        width: widthOfTab,
        height: 40,
        child: ValueListenableBuilder(
          valueListenable: selectedVideo,
          builder: (context, bool selectedVideoValue, child) => Center(
            child: Text(tapsNames.videoText,
                style: TextStyle(
                    fontSize: 14,
                    color: selectedVideoValue ? blackColor : Colors.grey,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
