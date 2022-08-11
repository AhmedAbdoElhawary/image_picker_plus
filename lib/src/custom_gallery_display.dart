import 'dart:io';
import 'package:custom_gallery_display/custom_gallery_display.dart';
import 'package:custom_gallery_display/src/images_view_page.dart';
import 'package:custom_gallery_display/src/utilities/enum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CustomGallery extends StatefulWidget {
  final Display display;
  final AppTheme? appTheme;
  final TabsTexts? tabsTexts;
  final bool enableCamera;
  final bool enableVideo;
  final bool cropImage;
  final SliverGridDelegate gridDelegate;
  final AsyncValueSetter<SelectedImagesDetails> sendRequestFunction;

  const CustomGallery.instagramDisplay({
    Key? key,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      crossAxisSpacing: 1.7,
      mainAxisSpacing: 1.5,
    ),
    this.tabsTexts,
    this.cropImage = true,
    this.enableCamera = true,
    this.enableVideo = true,
    required this.sendRequestFunction,
    this.appTheme,
  })  : display = Display.instagram,
        super(key: key);

  const CustomGallery.normalDisplay({
    Key? key,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 1.7,
      mainAxisSpacing: 1.5,
      childAspectRatio: .5,
    ),
    this.tabsTexts,
    this.enableCamera = false,
    this.enableVideo = false,
    required this.sendRequestFunction,
    this.appTheme,
  })  : display = Display.normal,
        cropImage = false,
        super(key: key);

  @override
  CustomGalleryState createState() => CustomGalleryState();
}

class CustomGalleryState extends State<CustomGallery>
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
  final ValueNotifier<bool?> stopScrollTab = ValueNotifier(null);
  ValueNotifier<File?> selectedCameraImage = ValueNotifier(null);
  ValueNotifier<File?> selectedImage = ValueNotifier(null);
  late AppTheme appTheme;
  late TabsTexts tapsNames;
  ValueNotifier<List<CameraDescription>>? cameras;
  late Color whiteColor;
  late Color blackColor;

  @override
  void initState() {
    appTheme = widget.appTheme ?? AppTheme();
    tapsNames = widget.tabsTexts ?? TabsTexts();
    whiteColor = appTheme.primaryColor;
    blackColor = appTheme.focusColor;
    _initializeCamera(0, true);
    super.initState();
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
    initializeControllerFuture.dispose();
    multiSelectionMode.dispose();
    showDeleteText.dispose();
    selectedVideo.dispose();
    selectedPage.dispose();
    stopScrollTab.dispose();
    selectedCameraImage.dispose();
    selectedImage.dispose();
    pageController.dispose();
    clearVideoRecord.dispose();
    redDeleteText.dispose();
    cameras!.dispose();
    multiSelectedImage.dispose();
    controller.dispose();
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
      pageController.value.animateTo(1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuad);
      selectedVideo.value = true;
      stopScrollTab.value = true;
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
                  if (widget.enableCamera || widget.enableVideo) cameraPage(),
                ],
              ),
            ),
          ),
          if (multiSelectedImage.value.length < 10) ...[
            if (widget.enableVideo || widget.enableCamera)
              ValueListenableBuilder(
                valueListenable: multiSelectionMode,
                builder: (context, bool multiSelectionModeValue, child) {
                  if (widget.display == Display.normal) {
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
        enableCamera: widget.enableCamera,
        onNewCameraSelected: _initializeCamera,
        enableVideo: widget.enableVideo,
        initializeControllerFuture: initializeControllerFuture,
        replacingTabBar: replacingDeleteWidget,
        clearVideoRecord: clearVideoRecord,
        redDeleteText: redDeleteText,
        moveToPage: widget.sendRequestFunction,
        moveToVideoScreen: moveToVideo,
        selectedVideo: selectedVideoValue,
      ),
    );
  }

  ImagesViewPage imagesViewPage() {
    return ImagesViewPage(
      appTheme: appTheme,
      selectedImage: selectedImage,
      gridDelegate: widget.gridDelegate,
      multiSelectionMode: multiSelectionMode,
      blackColor: blackColor,
      display: widget.display,
      tabsTexts: tapsNames,
      multiSelectedImage: multiSelectedImage,
      sendRequestFunction: widget.sendRequestFunction,
      whiteColor: whiteColor,
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
    bool cameraAndVideoEnabled = widget.enableCamera && widget.enableVideo;
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
                    width: widthOfScreen / 3,
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
                if (widget.enableCamera) photoTabBar(widthOfScreen, photoColor),
                if (widget.enableVideo) videoTabBar(widthOfScreen),
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
                ? widthOfScreen / 3
                : (selectedPageValue == SelectedPage.right
                    ? 0
                    : widthOfScreen / 1.5)),
            child: Container(
                height: 1,
                width: cameraAndVideoEnabled
                    ? widthOfScreen / 3
                    : widthOfScreen / 2,
                color: blackColor),
          ),
        ),
      ],
    );
  }

  GestureDetector photoTabBar(double widthOfScreen, Color textColor) {
    return GestureDetector(
      onTap: () => centerPage(numPage: 1, selectedPage: SelectedPage.center),
      child: SizedBox(
        width: widthOfScreen / 3,
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
      stopScrollTab.value = false;
    });
  }

  GestureDetector videoTabBar(double widthOfScreen) {
    return GestureDetector(
      onTap: () {
        setState(() {
          pageController.value.animateToPage(1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutQuad);
          selectedPage.value = SelectedPage.right;
          selectedVideo.value = true;
          stopScrollTab.value = true;
        });
      },
      child: SizedBox(
        width: widthOfScreen / 3,
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
