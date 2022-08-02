import 'dart:io';
import 'dart:typed_data';
import 'package:custom_gallery_display/src/app_theme.dart';
import 'package:custom_gallery_display/src/customPackages/crop_image/crop_image.dart';
import 'package:custom_gallery_display/src/customPackages/crop_image/crop_options.dart';
import 'package:custom_gallery_display/src/camera_display.dart';
import 'package:custom_gallery_display/src/image.dart';
import 'package:custom_gallery_display/src/selected_image_details.dart';
import 'package:custom_gallery_display/src/tabs_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';
import 'package:camera/camera.dart';

enum SelectedPage { left, center, right }

enum Display { instagram, normal, getImages }

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
  late ValueNotifier<TabController> tabController;
  final clearVideoRecord = ValueNotifier(false);
  final redDeleteText = ValueNotifier(false);
  final ValueNotifier<List<FutureBuilder<Uint8List?>>> _mediaList =
      ValueNotifier([]);
  final selectedPage = ValueNotifier(SelectedPage.left);
  late ValueNotifier<void> initializeControllerFuture;
  final cropKey = GlobalKey<CropState>();
  ValueNotifier<List<File>> multiSelectedImage = ValueNotifier([]);
  late ValueNotifier<CameraController> controller;
  final multiSelectionMode = ValueNotifier(false);
  final showDeleteText = ValueNotifier(false);
  final selectedVideo = ValueNotifier(false);
  ValueNotifier<List<File?>> allImages = ValueNotifier([]);
  ScrollController scrollController = ScrollController();
  final isImagesReady = ValueNotifier(true);
  final expandImage = ValueNotifier(false);
  final expandHeight = ValueNotifier(0.0);
  final moveAwayHeight = ValueNotifier(0.0);
  final expandImageView = ValueNotifier(false);

  /// To avoid lag when you interacting with image when it expanded
  final enableVerticalTapping = ValueNotifier(false);
  final remove = ValueNotifier(false);
  final ValueNotifier<bool?> stopScrollTab = ValueNotifier(null);
  final currentPage = ValueNotifier(0);
  ValueNotifier<File?> selectedCameraImage = ValueNotifier(null);
  ValueNotifier<File?> selectedImage = ValueNotifier(null);
  final lastPage = ValueNotifier(0);
  late AppTheme appTheme;
  late TabsTexts tapsNames;
  ValueNotifier<List<CameraDescription>>? cameras;
  bool noImages = false;
  bool noPaddingForGridView = false;
  bool noDuration = false;
  double scrollPixels = 0.0;

  @override
  void initState() {
    appTheme = widget.appTheme ?? AppTheme();
    tapsNames = widget.tabsTexts ?? TabsTexts();
    _initializeCamera(0, true);
    isImagesReady.value = false;
    int lengthOfTabs = 1;

    if (widget.enableCamera || widget.enableVideo) {
      lengthOfTabs = 2;
    }
    tabController =
        ValueNotifier(TabController(length: lengthOfTabs, vsync: this));
    _fetchNewMedia(currentPageValue: 0, lastPageValue: 0);
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
    allImages.dispose();
    isImagesReady.dispose();
    expandImage.dispose();
    expandHeight.dispose();
    moveAwayHeight.dispose();
    expandImageView.dispose();
    enableVerticalTapping.dispose();
    remove.dispose();
    selectedPage.dispose();
    stopScrollTab.dispose();
    selectedCameraImage.dispose();
    selectedImage.dispose();
    tabController.dispose();
    clearVideoRecord.dispose();
    redDeleteText.dispose();
    _mediaList.dispose();
    cameras!.dispose();
    multiSelectedImage.dispose();
    scrollController.dispose();
    controller.dispose();

    super.dispose();
  }

  bool _handleScrollEvent(ScrollNotification scroll,
      {required int currentPageValue, required int lastPageValue}) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPageValue != lastPageValue) {
        _fetchNewMedia(
            currentPageValue: currentPageValue, lastPageValue: lastPageValue);
        return true;
      }
    }
    return false;
  }

  _fetchNewMedia(
      {required int currentPageValue, required int lastPageValue}) async {
    lastPage.value = currentPageValue;
    var result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          onlyAll: true, type: RequestType.image);
      if (albums.isEmpty) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => setState(() => noImages = true));
        return;
      } else if (noImages) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => setState(() => noImages = false));
      }
      List<AssetEntity> media =
          await albums[0].getAssetListPaged(page: currentPageValue, size: 60);
      List<FutureBuilder<Uint8List?>> temp = [];
      List<File?> imageTemp = [];
      for (int i = 0; i < media.length; i++) {
        FutureBuilder<Uint8List?> gridViewImage =
            await getImageGallery(media, i);
        File? image = await highQualityImage(media, i);
        if (selectedImage.value == null && i == 0) selectedImage.value = image;
        temp.add(gridViewImage);
        imageTemp.add(image);
      }
      _mediaList.value.addAll(temp);
      allImages.value.addAll(imageTemp);
      currentPage.value++;
      isImagesReady.value = true;
    } else {
      await PhotoManager.requestPermissionExtend();
      PhotoManager.openSetting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return noImages
        ? const Center(
            child: Text(
              "There is no images",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )
        : defaultTabController();
  }

  Future<FutureBuilder<Uint8List?>> getImageGallery(
      List<AssetEntity> media, int i) async {
    bool isThatNormalDisplay = widget.display == Display.normal;
    FutureBuilder<Uint8List?> futureBuilder = FutureBuilder(
      future: media[i].thumbnailDataWithSize(isThatNormalDisplay
          ? const ThumbnailSize(350, 350)
          : const ThumbnailSize(200, 200)),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Uint8List? image = snapshot.data;
          if (image != null) {
            return Container(
              color: const Color.fromARGB(255, 189, 189, 189),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: MemoryImageDisplay(
                        imageBytes: image, appTheme: appTheme),
                  ),
                  if (media[i].type == AssetType.video)
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 5, bottom: 5),
                        child: Icon(
                          Icons.slow_motion_video_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
        }
        return Container();
      },
    );
    return futureBuilder;
  }

  Future<File?> highQualityImage(List<AssetEntity> media, int i) async =>
      media[i].file;

  AppBar appBar() {
    return AppBar(
      backgroundColor: appTheme.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.clear_rounded, color: appTheme.focusColor, size: 30),
        onPressed: () {
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  Widget loadingWidget() {
    bool isThatInstagramDisplay = widget.display == Display.instagram;
    return SingleChildScrollView(
      child: Column(
        children: [
          appBar(),
          Shimmer.fromColors(
            baseColor: appTheme.shimmerBaseColor,
            highlightColor: appTheme.shimmerHighlightColor,
            child: Column(
              children: [
                if (isThatInstagramDisplay) ...[
                  Container(
                      color: const Color(0xff696969),
                      height: 360,
                      width: double.infinity),
                  const SizedBox(height: 1),
                ],
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  primary: false,
                  gridDelegate: widget.gridDelegate,
                  itemBuilder: (context, index) {
                    return Container(
                        color: const Color(0xff696969), width: double.infinity);
                  },
                  itemCount: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                multiSelectedImage.value = [];
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
      tabController.value.animateTo(1);
      selectedVideo.value = true;
      stopScrollTab.value = true;
      remove.value = true;
    });
  }

  DefaultTabController defaultTabController() {
    Color whiteColor = appTheme.primaryColor;
    return DefaultTabController(
        length: 2,
        child: Material(
          color: whiteColor,
          child: safeArea(),
        ));
  }

  SafeArea safeArea() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ValueListenableBuilder(
              valueListenable: tabController,
              builder: (context, TabController tabControllerValue, child) =>
                  TabBarView(
                controller: tabControllerValue,
                dragStartBehavior: DragStartBehavior.start,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  buildGridView(),
                  if (widget.enableCamera || widget.enableVideo)
                    ValueListenableBuilder(
                      valueListenable: selectedVideo,
                      builder: (context, bool selectedVideoValue, child) =>
                          CustomCameraDisplay(
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
                    ),
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

  ValueListenableBuilder<bool> buildTabBar() {
    return ValueListenableBuilder(
      valueListenable: showDeleteText,
      builder: (context, bool showDeleteTextValue, child) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeIn,
          child: showDeleteTextValue ? tapBarMessage(true) : tabBar()),
    );
  }

  ValueListenableBuilder<bool> buildGridView() {
    return ValueListenableBuilder(
      valueListenable: isImagesReady,
      builder: (context, bool isImagesReadyValue, child) {
        if (isImagesReadyValue) {
          return ValueListenableBuilder(
            valueListenable: _mediaList,
            builder: (context, List<FutureBuilder<Uint8List?>> mediaListValue,
                child) {
              return ValueListenableBuilder(
                valueListenable: lastPage,
                builder: (context, int lastPageValue, child) =>
                    ValueListenableBuilder(
                  valueListenable: currentPage,
                  builder: (context, int currentPageValue, child) {
                    if (widget.display == Display.normal) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          normalAppBar(),
                          Flexible(
                              child: normalGridView(mediaListValue,
                                  currentPageValue, lastPageValue)),
                        ],
                      );
                    } else {
                      return instagramGridView(
                          mediaListValue, currentPageValue, lastPageValue);
                    }
                  },
                ),
              );
            },
          );
        } else {
          return loadingWidget();
        }
      },
    );
  }

  Widget tabBar() {
    double width = MediaQuery.of(context).size.width;
    Color blackColor = appTheme.focusColor;
    bool cameraAndVideoEnabled = widget.enableCamera && widget.enableVideo;
    double labelPadding = cameraAndVideoEnabled ? 13.0 : 0.0;
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: tabController,
                builder: (context, TabController tabControllerValue, child) =>
                    ValueListenableBuilder(
                  valueListenable: selectedVideo,
                  builder: (context, bool selectedVideoValue, child) => TabBar(
                    indicatorWeight: 1,
                    controller: tabControllerValue,
                    unselectedLabelColor: Colors.grey,
                    labelColor: selectedVideoValue ? Colors.grey : blackColor,
                    indicatorColor:
                        !selectedVideoValue ? blackColor : Colors.transparent,
                    labelPadding: EdgeInsets.all(labelPadding),
                    tabs: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            centerPage(
                                numPage: 0, selectedPage: SelectedPage.left);
                          });
                        },
                        child: Text(tapsNames.galleryText,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      if (widget.enableCamera) ...[
                        photoTabBar()
                      ] else ...[
                        videoTabBar(blackColor)
                      ]
                    ],
                  ),
                ),
              ),
            ),
            if (cameraAndVideoEnabled) videoTabBar(blackColor),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: remove,
          builder: (context, bool removeValue, child) => Visibility(
            visible: removeValue,
            child: ValueListenableBuilder(
              valueListenable: selectedPage,
              builder: (context, SelectedPage selectedPageValue, child) =>
                  AnimatedPositioned(
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInBack,
                      onEnd: () {
                        if (selectedPageValue != SelectedPage.right) {
                          remove.value = false;
                        }
                      },
                      left: selectedPageValue == SelectedPage.left
                          ? 0
                          : (selectedPageValue == SelectedPage.center
                              ? width / 3
                              : (cameraAndVideoEnabled
                                  ? width / 1.5
                                  : width / 2)),
                      child: Container(
                          height: 1,
                          width: cameraAndVideoEnabled ? width / 3 : width / 2,
                          color: blackColor)),
            ),
          ),
        ),
      ],
    );
  }

  GestureDetector photoTabBar() {
    return GestureDetector(
      onTap: () {
        centerPage(numPage: 1, selectedPage: SelectedPage.center);
      },
      child: Text(tapsNames.photoText,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  centerPage({required int numPage, required SelectedPage selectedPage}) {
    setState(() {
      this.selectedPage.value = selectedPage;
      tabController.value.animateTo(numPage);
      selectedVideo.value = false;
      stopScrollTab.value = false;
      remove.value = false;
    });
  }

  GestureDetector videoTabBar(Color blackColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          tabController.value.animateTo(1);
          selectedPage.value = SelectedPage.right;
          selectedVideo.value = true;
          stopScrollTab.value = true;
          remove.value = true;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 40),
        child: ValueListenableBuilder(
          valueListenable: selectedVideo,
          builder: (context, bool selectedVideoValue, child) => Text(
              tapsNames.videoText,
              style: TextStyle(
                  fontSize: 14,
                  color: selectedVideoValue ? blackColor : Colors.grey,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget normalAppBar() {
    Color whiteColor = appTheme.primaryColor;
    Color blackColor = appTheme.focusColor;
    double width = MediaQuery.of(context).size.width;
    return Container(
      color: whiteColor,
      height: 60,
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          existButton(blackColor),
          const Spacer(),
          doneButton(),
        ],
      ),
    );
  }

  IconButton existButton(Color blackColor) {
    return IconButton(
      icon: Icon(Icons.clear_rounded, color: blackColor, size: 30),
      onPressed: () {
        Navigator.of(context).maybePop();
      },
    );
  }

  IconButton doneButton() {
    return IconButton(
      icon:
          const Icon(Icons.arrow_forward_rounded, color: Colors.blue, size: 30),
      onPressed: () async {
        double aspect = expandImage.value ? 6 / 8 : 1.0;
        if (!multiSelectionMode.value) {
          File? image = selectedImage.value;
          if (image != null) {
            File? croppedImage = await cropImage(image);
            if (croppedImage != null) {
              SelectedImagesDetails details = SelectedImagesDetails(
                selectedFile: croppedImage,
                multiSelectionMode: false,
                aspectRatio: aspect,
              );
              widget.sendRequestFunction(details);
            }
          }
        } else {
          List<File> selectedImages = [];
          for (int i = 0; i < multiSelectedImage.value.length; i++) {
            File? croppedImage = await cropImage(multiSelectedImage.value[i]);
            if (croppedImage != null) {
              selectedImages.add(croppedImage);
            }
          }
          if (selectedImages.isNotEmpty) {
            SelectedImagesDetails details = SelectedImagesDetails(
              selectedFile: selectedImages[0],
              selectedFiles: selectedImages,
              multiSelectionMode: true,
              aspectRatio: aspect,
            );
            widget.sendRequestFunction(details);
          }
        }
      },
    );
  }

  Future<File?> cropImage(File imageFile) async {
    if (widget.cropImage) {
      await ImageCrop.requestPermissions();
      final scale = cropKey.currentState!.scale;
      final area = cropKey.currentState!.area;
      if (area == null) {
        return null;
      }
      final sample = await ImageCrop.sampleImage(
        file: imageFile,
        preferredSize: (2000 / scale).round(),
      );

      final File file = await ImageCrop.cropImage(
        file: sample,
        area: area,
      );
      sample.delete();
      return file;
    } else {
      return imageFile;
    }
  }

  Container showSelectedImage(
      BuildContext context, File selectedImageValue, Color whiteColor) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      key: GlobalKey(debugLabel: "have image"),
      color: whiteColor,
      height: 360,
      width: width,
      child: ValueListenableBuilder(
        valueListenable: multiSelectionMode,
        builder: (context, bool multiSelectionModeValue, child) => Stack(
          children: [
            ValueListenableBuilder(
              valueListenable: expandImage,
              builder: (context, bool expandImageValue, child) => Crop.file(
                selectedImageValue,
                key: cropKey,
                paintColor: widget.appTheme != null
                    ? widget.appTheme!.primaryColor
                    : null,
                aspectRatio: expandImageValue ? 6 / 8 : 1.0,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      multiSelectionMode.value = !multiSelectionMode.value;
                      if (!multiSelectionModeValue) {
                        multiSelectedImage.value = [];
                      }
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
                          child: Icon(
                        Icons.copy,
                        color: Colors.white,
                        size: 17,
                      ))),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      expandImage.value = !expandImage.value;
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
                    child: customArrowsIcon(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stack customArrowsIcon() {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(5.0),
        child: Align(
          alignment: Alignment.topRight,
          child: Transform.rotate(
            angle: 180 * math.pi / 250,
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(5.0),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Transform.rotate(
            angle: 180 * math.pi / 255,
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ),
    ]);
  }

  bool selectionImageCheck(File image, List<File> multiSelectionValue,
      {bool enableCopy = false}) {
    if (multiSelectionValue.contains(image) && selectedImage.value == image) {
      setState(() {
        multiSelectedImage.value.remove(image);
        if (multiSelectionValue.isNotEmpty) {
          selectedImage.value = multiSelectedImage.value.last;
        }
      });

      return true;
    } else {
      if (multiSelectionValue.length < 10) {
        setState(() {
          if (!multiSelectionValue.contains(image)) {
            multiSelectedImage.value.add(image);
          }
          if (enableCopy) {
            selectedImage.value = image;
          }
        });
      }
      return false;
    }
  }

  bool isScrolling = false;

  Widget instagramGridView(List<FutureBuilder<Uint8List?>> mediaListValue,
      int currentPageValue, int lastPageValue) {
    Color whiteColor = appTheme.primaryColor;
    return ValueListenableBuilder(
      valueListenable: expandHeight,
      builder: (context, double expandedHeightValue, child) {
        return ValueListenableBuilder(
          valueListenable: moveAwayHeight,
          builder: (context, double moveAwayHeightValue, child) =>
              ValueListenableBuilder(
            valueListenable: expandImageView,
            builder: (context, bool expandImageValue, child) {
              double a = expandedHeightValue - 360;
              double expandHeightV = a < 0 ? a : 0;
              double moveAwayHeightV =
                  moveAwayHeightValue < 360 ? moveAwayHeightValue * -1 : -360;
              double topPosition =
                  expandImageValue ? expandHeightV : moveAwayHeightV;
              enableVerticalTapping.value = !(topPosition == 0);
              double padding = 2;
              if (scrollPixels < 420) {
                double pixels = 420 - scrollPixels;
                padding = pixels >= 62 ? pixels + 2 : 62;
              } else if (expandImageValue) {
                padding = 62;
              } else if (noPaddingForGridView) {
                padding = 62;
              } else {
                padding = topPosition + 422;
              }
              int duration = noDuration ? 0 : 250;

              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: padding),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        expandImageView.value = false;
                        moveAwayHeight.value = scrollController.position.pixels;
                        scrollPixels = scrollController.position.pixels;
                        setState(() {
                          isScrolling = true;
                          noPaddingForGridView = false;
                          noDuration = false;
                          if (notification is ScrollEndNotification) {
                            expandHeight.value =
                                expandedHeightValue > 240 ? 360 : 0;
                            isScrolling = false;
                          }
                        });

                        _handleScrollEvent(notification,
                            currentPageValue: currentPageValue,
                            lastPageValue: lastPageValue);
                        return true;
                      },
                      child: GridView.builder(
                        gridDelegate: widget.gridDelegate,
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return buildImage(mediaListValue, index);
                        },
                        itemCount: mediaListValue.length,
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    top: topPosition,
                    duration: Duration(milliseconds: duration),
                    child: Column(
                      children: [
                        normalAppBar(),
                        buildImageView(
                            whiteColor, expandedHeightValue, topPosition),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Container container() => Container(
        height: 620,
        color: Colors.red,
      );

  Widget normalGridView(List<FutureBuilder<Uint8List?>> mediaListValue,
      int currentPageValue, int lastPageValue) {
    return NotificationListener(
      onNotification: (ScrollNotification notification) {
        _handleScrollEvent(notification,
            currentPageValue: currentPageValue, lastPageValue: lastPageValue);
        return true;
      },
      child: GridView.builder(
        gridDelegate: widget.gridDelegate,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return buildImage(mediaListValue, index);
        },
        itemCount: mediaListValue.length,
      ),
    );
  }

  Widget buildImageView(
      Color whiteColor, double expandedHeightValue, double topPositionValue) {
    return ValueListenableBuilder(
      valueListenable: enableVerticalTapping,
      builder: (context, bool enableTappingValue, child) => GestureDetector(
        onVerticalDragUpdate: enableTappingValue
            ? (details) {
                expandImageView.value = true;
                expandHeight.value = details.globalPosition.dy - 60;
                setState(() => noDuration = true);
              }
            : null,
        onVerticalDragEnd: enableTappingValue
            ? (details) {
                expandHeight.value = expandedHeightValue > 260 ? 360 : 0;
                if (topPositionValue == -360) {
                  enableVerticalTapping.value = true;
                }
                if (topPositionValue == 0) enableVerticalTapping.value = false;
                setState(() => noDuration = false);
              }
            : null,
        child: ValueListenableBuilder(
          valueListenable: selectedImage,
          builder: (context, File? selectedImageValue, child) {
            if (selectedImageValue != null) {
              return showSelectedImage(context, selectedImageValue, whiteColor);
            } else {
              return Container(key: GlobalKey(debugLabel: "do not have"));
            }
          },
        ),
      ),
    );
  }

  ValueListenableBuilder<File?> buildImage(
      List<FutureBuilder<Uint8List?>> mediaListValue, int index) {
    return ValueListenableBuilder(
      valueListenable: selectedImage,
      builder: (context, File? selectedImageValue, child) {
        return ValueListenableBuilder(
            valueListenable: allImages,
            builder: (context, List<File?> allImagesValue, child) {
              FutureBuilder<Uint8List?> mediaList = mediaListValue[index];
              File? image = allImagesValue[index];
              if (image != null) {
                bool imageSelected = multiSelectedImage.value.contains(image);
                return Stack(
                  children: [
                    gestureDetector(image, index, mediaList),
                    if (selectedImageValue == image)
                      gestureDetector(image, index, blurContainer()),
                    _MultiSelectionMode(
                      image: image,
                      multiSelectionModeValue: multiSelectionMode.value,
                      imageSelected: imageSelected,
                      multiSelectedImageValue: multiSelectedImage.value,
                    ),
                  ],
                );
              } else {
                return Container();
              }
            });
      },
    );
  }

  Container blurContainer() {
    return Container(
      width: double.infinity,
      color: const Color.fromARGB(184, 234, 234, 234),
      height: double.maxFinite,
    );
  }

  Widget gestureDetector(File image, int index, Widget childWidget) {
    return GestureDetector(
        onTap: () {
          setState(() {
            if (multiSelectionMode.value) {
              bool close = selectionImageCheck(image, multiSelectedImage.value);
              if (close) return;
            }
            selectedImage.value = image;
            expandImageView.value = false;
            moveAwayHeight.value = 0;
            enableVerticalTapping.value = false;
            noPaddingForGridView = true;
          });
        },
        onLongPress: () {
          if (!multiSelectionMode.value) {
            multiSelectionMode.value = true;
          }
        },
        onLongPressUp: () {
          selectionImageCheck(image, multiSelectedImage.value,
              enableCopy: true);
          expandImageView.value = false;
          moveAwayHeight.value = 0;

          enableVerticalTapping.value = false;
          setState(() => noPaddingForGridView = true);
        },
        child: childWidget);
  }
}

class _MultiSelectionMode extends StatelessWidget {
  final bool multiSelectionModeValue;
  final bool imageSelected;
  final List<File> multiSelectedImageValue;
  final File image;
  const _MultiSelectionMode(
      {Key? key,
      required this.image,
      required this.imageSelected,
      required this.multiSelectedImageValue,
      required this.multiSelectionModeValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: multiSelectionModeValue,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
              color: imageSelected
                  ? Colors.blue
                  : const Color.fromARGB(115, 222, 222, 222),
              border: Border.all(
                color: Colors.white,
              ),
              shape: BoxShape.circle,
            ),
            child: imageSelected
                ? Center(
                    child: Text(
                    "${multiSelectedImageValue.indexOf(image) + 1}",
                    style: const TextStyle(color: Colors.white),
                  ))
                : Container(),
          ),
        ),
      ),
    );
  }
}
