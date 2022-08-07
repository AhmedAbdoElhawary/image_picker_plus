import 'dart:io';
import 'dart:typed_data';
import 'package:custom_gallery_display/src/entities/app_theme.dart';
import 'package:custom_gallery_display/src/crop_image_view.dart';
import 'package:custom_gallery_display/src/custom_packages/crop_image/crop_image.dart';
import 'package:custom_gallery_display/src/image.dart';
import 'package:custom_gallery_display/src/image_editor.dart';
import 'package:custom_gallery_display/src/multi_selection_mode.dart';
import 'package:custom_gallery_display/src/entities/selected_image_details.dart';
import 'package:custom_gallery_display/src/utilities/enum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_crop/image_crop.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:ui' as ui;
import 'package:shimmer/shimmer.dart';

class ImagesViewPage extends StatefulWidget {
  final ValueNotifier<List<File>> multiSelectedImage;
  final ValueNotifier<bool> multiSelectionMode;
  final ValueNotifier<bool> isThatImageFilter;

  /// To avoid lag when you interacting with image when it expanded
  final ValueNotifier<File?> selectedImage;
  final ValueNotifier<TabController> editViewTabController;
  final AppTheme appTheme;
  final Color whiteColor;
  final Color blackColor;
  final Display display;
  final SliverGridDelegate gridDelegate;
  final AsyncValueSetter<SelectedImagesDetails> sendRequestFunction;
  const ImagesViewPage({
    Key? key,
    required this.multiSelectedImage,
    required this.multiSelectionMode,
    required this.isThatImageFilter,
    required this.selectedImage,
    required this.editViewTabController,
    required this.appTheme,
    required this.whiteColor,
    required this.blackColor,
    required this.display,
    required this.gridDelegate,
    required this.sendRequestFunction,
  }) : super(key: key);

  @override
  State<ImagesViewPage> createState() => _ImagesViewPageState();
}

class _ImagesViewPageState extends State<ImagesViewPage> {
  final ValueNotifier<List<FutureBuilder<Uint8List?>>> _mediaList =
      ValueNotifier([]);
  ValueNotifier<List<File?>> allImages = ValueNotifier([]);
  final ValueNotifier<int> indexOfFilter = ValueNotifier(0);
  ScrollController scrollController = ScrollController();
  final expandImage = ValueNotifier(false);
  final expandHeight = ValueNotifier(0.0);
  final moveAwayHeight = ValueNotifier(0.0);
  final expandImageView = ValueNotifier(false);
  final ValueNotifier<GlobalKey> globalKey = ValueNotifier(GlobalKey());

  /// To avoid lag when you interacting with image when it expanded
  final enableVerticalTapping = ValueNotifier(false);
  final cropKey = ValueNotifier(GlobalKey<CustomCropState>());
  bool noPaddingForGridView = false;
  final isImagesReady = ValueNotifier(true);
  final currentPage = ValueNotifier(0);
  final lastPage = ValueNotifier(0);
  double scrollPixels = 0.0;
  bool isScrolling = false;
  bool noImages = false;
  final noDuration = ValueNotifier(false);

  @override
  void dispose() {
    _mediaList.dispose();
    allImages.dispose();
    indexOfFilter.dispose();
    scrollController.dispose();
    isImagesReady.dispose();
    currentPage.dispose();
    lastPage.dispose();
    expandImage.dispose();
    expandHeight.dispose();
    moveAwayHeight.dispose();
    expandImageView.dispose();
    enableVerticalTapping.dispose();
    cropKey.dispose();
    noDuration.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _fetchNewMedia(currentPageValue: 0, lastPageValue: 0);
    isImagesReady.value = false;

    super.initState();
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
        if (widget.selectedImage.value == null && i == 0) {
          widget.selectedImage.value = image;
        }
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
                        imageBytes: image, appTheme: widget.appTheme),
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

  @override
  Widget build(BuildContext context) {
    return noImages
        ? const Center(
            child: Text(
              "There is no images",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )
        : buildGridView();
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
                      return widget.isThatImageFilter.value
                          ? buildImageFilterView()
                          : instagramGridView(
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

  Widget loadingWidget() {
    bool isThatInstagramDisplay = widget.display == Display.instagram;
    return SingleChildScrollView(
      child: Column(
        children: [
          appBar(),
          Shimmer.fromColors(
            baseColor: widget.appTheme.shimmerBaseColor,
            highlightColor: widget.appTheme.shimmerHighlightColor,
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

  AppBar appBar() {
    return AppBar(
      backgroundColor: widget.appTheme.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.clear_rounded,
            color: widget.appTheme.focusColor, size: 30),
        onPressed: () {
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  Widget normalAppBar() {
    double width = MediaQuery.of(context).size.width;
    return Container(
      color: widget.whiteColor,
      height: 56,
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          existButton(),
          const Spacer(),
          doneButton(),
        ],
      ),
    );
  }

  IconButton existButton() {
    return IconButton(
      icon: Icon(Icons.clear_rounded, color: widget.blackColor, size: 30),
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
        if (!widget.multiSelectionMode.value) {
          File? image = widget.selectedImage.value;
          if (image != null) {
            // SelectedImagesDetails details = SelectedImagesDetails(
            //   selectedFile: image,
            //   multiSelectionMode: false,
            //   aspectRatio: aspect,
            //   selectedFiles: [image],
            // );
            // Uint8List uint8Image = await image.readAsBytes();
            widget.isThatImageFilter.value = true;
            setState(() {});
            // Navigator.of(context).push(
            //   MaterialPageRoute(
            //     builder: (context) => ImageEditor(
            //       details: details,
            //       appTheme: appTheme,
            //       selectedImage: uint8Image,
            //       // cropKey: filterCropKey,
            //       sendRequestFunction: widget.sendRequestFunction,
            //     ),
            //   ),
            // );
          }
        } else {
          List<File> selectedImages = [];
          for (int i = 0; i < widget.multiSelectedImage.value.length; i++) {}
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

  ValueListenableBuilder<File?> buildImage(
      List<FutureBuilder<Uint8List?>> mediaListValue, int index) {
    return ValueListenableBuilder(
      valueListenable: widget.selectedImage,
      builder: (context, File? selectedImageValue, child) {
        return ValueListenableBuilder(
            valueListenable: allImages,
            builder: (context, List<File?> allImagesValue, child) {
              FutureBuilder<Uint8List?> mediaList = mediaListValue[index];
              File? image = allImagesValue[index];
              if (image != null) {
                bool imageSelected =
                    widget.multiSelectedImage.value.contains(image);
                return Stack(
                  children: [
                    gestureDetector(image, index, mediaList),
                    if (selectedImageValue == image)
                      gestureDetector(image, index, blurContainer()),
                    MultiSelectionMode(
                      image: image,
                      multiSelectionModeValue: widget.multiSelectionMode.value,
                      imageSelected: imageSelected,
                      multiSelectedImageValue: widget.multiSelectedImage.value,
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
            if (widget.multiSelectionMode.value) {
              bool close =
                  selectionImageCheck(image, widget.multiSelectedImage.value);
              if (close) return;
            }
            widget.selectedImage.value = image;
            expandImageView.value = false;
            moveAwayHeight.value = 0;
            enableVerticalTapping.value = false;
            noPaddingForGridView = true;
          });
        },
        onLongPress: () {
          if (!widget.multiSelectionMode.value) {
            widget.multiSelectionMode.value = true;
          }
        },
        onLongPressUp: () {
          selectionImageCheck(image, widget.multiSelectedImage.value,
              enableCopy: true);
          expandImageView.value = false;
          moveAwayHeight.value = 0;

          enableVerticalTapping.value = false;
          setState(() => noPaddingForGridView = true);
        },
        child: childWidget);
  }

  bool selectionImageCheck(File image, List<File> multiSelectionValue,
      {bool enableCopy = false}) {
    if (multiSelectionValue.contains(image) &&
        widget.selectedImage.value == image) {
      setState(() {
        widget.multiSelectedImage.value.remove(image);
        if (multiSelectionValue.isNotEmpty) {
          widget.selectedImage.value = widget.multiSelectedImage.value.last;
        }
      });

      return true;
    } else {
      if (multiSelectionValue.length < 10) {
        setState(() {
          if (!multiSelectionValue.contains(image)) {
            widget.multiSelectedImage.value.add(image);
          }
          if (enableCopy) {
            widget.selectedImage.value = image;
          }
        });
      }
      return false;
    }
  }

  Widget buildImageFilterView() {
    return ValueListenableBuilder(
      valueListenable: widget.selectedImage,
      builder: (context, File? selectedImageValue, child) {
        return Column(
          children: [
            editViewAppBar(),
            CropImageView(
              cropKey: cropKey,
              selectedImage: widget.selectedImage,
              appTheme: widget.appTheme,
              multiSelectionMode: widget.multiSelectionMode,
              enableVerticalTapping: enableVerticalTapping,
              expandHeight: expandHeight,
              expandImage: expandImage,
              expandImageView: expandImageView,
              globalKey: globalKey,
              indexOfFilter: indexOfFilter,
              multiSelectedImage: widget.multiSelectedImage,
              noDuration: noDuration,
              whiteColor: widget.whiteColor,
            ),
            Flexible(
                child: ImageEditor(
              indexOfFilter: indexOfFilter,
              appTheme: widget.appTheme,
              selectedImage: selectedImageValue,
              editViewTabController: widget.editViewTabController,
              whiteColor: widget.whiteColor,
            )),
          ],
        );
      },
    );
  }

  AppBar editViewAppBar() {
    return AppBar(
      backgroundColor: widget.whiteColor,
      elevation: 0,
      centerTitle: true,
      title: Icon(Icons.edit_off_rounded, color: widget.blackColor),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: widget.blackColor),
        onPressed: () {
          setState(() {
            widget.isThatImageFilter.value = false;
            indexOfFilter.value = 0;
          });
          // Navigator.pop(context);
        },
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: cropKey,
          builder: (context, GlobalKey<CustomCropState> cropKeyValue, child) =>
              ValueListenableBuilder(
            valueListenable: expandImage,
            builder: (context, bool expandImageValue, child) => IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.blue),
              onPressed: () async {
                RenderRepaintBoundary? repaintBoundary =
                    globalKey.value.currentContext?.findRenderObject()
                        as RenderRepaintBoundary?;
                ui.Image? boxImage =
                    await repaintBoundary?.toImage(pixelRatio: 10);
                ByteData? byteData =
                    await boxImage?.toByteData(format: ui.ImageByteFormat.png);
                Uint8List? image = byteData?.buffer.asUint8List();
                if (image == null) return;
                final tempDir = await getTemporaryDirectory();
                File img = await File('${tempDir.path}/image.png').create();
                img.writeAsBytesSync(image);

                File? croppedImage = await cropImage(img, cropKeyValue);
                if (croppedImage == null) return;
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => SecondScreen(
                //         imageData: expandImageValue ? croppedImage : img)));
                // widget.details.selectedBytes =i!;
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<File?> cropImage(
      File imageFile, GlobalKey<CustomCropState> cropKeyValue) async {
    await ImageCrop.requestPermissions();
    final scale = cropKeyValue.currentState!.scale;
    final area = cropKeyValue.currentState!.area;
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
  }

  Widget instagramGridView(List<FutureBuilder<Uint8List?>> mediaListValue,
      int currentPageValue, int lastPageValue) {
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
              if (scrollPixels < 416) {
                double pixels = 416 - scrollPixels;
                padding = pixels >= 58 ? pixels + 2 : 58;
              } else if (expandImageValue) {
                padding = 58;
              } else if (noPaddingForGridView) {
                padding = 58;
              } else {
                padding = topPosition + 418;
              }
              int duration = noDuration.value ? 0 : 250;

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
                          noDuration.value = false;
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
                        CropImageView(
                          cropKey: cropKey,
                          selectedImage: widget.selectedImage,
                          appTheme: widget.appTheme,
                          multiSelectionMode: widget.multiSelectionMode,
                          enableVerticalTapping: enableVerticalTapping,
                          expandHeight: expandHeight,
                          expandImage: expandImage,
                          expandImageView: expandImageView,
                          globalKey: globalKey,
                          indexOfFilter: indexOfFilter,
                          multiSelectedImage: widget.multiSelectedImage,
                          noDuration: noDuration,
                          topPosition: topPosition,
                          whiteColor: widget.whiteColor,
                        ),
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
}
