import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:custom_gallery_display/src/entities/app_theme.dart';
import 'package:custom_gallery_display/src/custom_packages/crop_image/crop_image.dart';
import 'package:custom_gallery_display/src/utilities/enum.dart';
import 'package:custom_gallery_display/src/utilities/typedef.dart';
import 'package:custom_gallery_display/src/video_layout/record_count.dart';
import 'package:custom_gallery_display/src/video_layout/record_fade_animation.dart';
import 'package:custom_gallery_display/src/entities/selected_image_details.dart';
import 'package:custom_gallery_display/src/entities/tabs_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:image_crop/image_crop.dart';

// ignore: must_be_immutable
class CustomCameraDisplay extends StatefulWidget {
  final bool selectedVideo;
  final AppTheme appTheme;
  final TabsTexts tapsNames;
  final bool enableCamera;
  final bool enableVideo;
  late ValueNotifier<CameraController> controller;
  final VoidCallback moveToVideoScreen;
  final ValueNotifier<File?> selectedCameraImage;
  final ValueNotifier<bool> redDeleteText;
  final ValueChanged<bool> replacingTabBar;
  final ValueNotifier<bool> clearVideoRecord;
  late ValueNotifier<void> initializeControllerFuture;
  final AsyncValueSetter<SelectedImagesDetails> moveToPage;
  final CustomAsyncValueSetter<Future<void>, int, bool> onNewCameraSelected;

  ValueNotifier<List<CameraDescription>>? cameras;

  CustomCameraDisplay({
    Key? key,
    required this.appTheme,
    required this.tapsNames,
    required this.selectedCameraImage,
    required this.enableCamera,
    required this.enableVideo,
    required this.moveToPage,
    required this.controller,
    required this.onNewCameraSelected,
    required this.redDeleteText,
    required this.selectedVideo,
    required this.replacingTabBar,
    required this.clearVideoRecord,
    required this.cameras,
    required this.moveToVideoScreen,
    required this.initializeControllerFuture,
  }) : super(key: key);

  @override
  CustomCameraDisplayState createState() => CustomCameraDisplayState();
}

class CustomCameraDisplayState extends State<CustomCameraDisplay> {
  ValueNotifier<bool> startVideoCount = ValueNotifier(false);
  final cropKey = GlobalKey<CustomCropState>();
  Flash currentFlashMode = Flash.auto;
  late Widget videoStatusAnimation;
  int selectedCamera = 0;
  File? videoRecordFile;

  @override
  void initState() {
    videoStatusAnimation = Container();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    Color whiteColor = widget.appTheme.primaryColor;
    File? selectedImage = widget.selectedCameraImage.value;
    return Stack(
      children: [
        if (selectedImage == null) ...[
          Container(
            width: double.infinity,
            color: Colors.blue,
            child: CameraPreview(widget.controller.value),
          ),
        ] else ...[
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              color: whiteColor,
              height: 360,
              width: double.infinity,
              child: selectedCamera == 0
                  ? buildCrop(selectedImage)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: buildCrop(selectedImage),
                    ),
            ),
          )
        ],
        buildRotationIcon(context),
        buildFlashIcons(),
        buildPickImageContainer(whiteColor, context),
      ],
    );
  }

  Align buildPickImageContainer(Color whiteColor, BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 270,
        color: whiteColor,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: RecordCount(
                  appTheme: widget.appTheme,
                  startVideoCount: startVideoCount,
                  makeProgressRed: widget.redDeleteText,
                  clearVideoRecord: widget.clearVideoRecord,
                ),
              ),
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  padding: const EdgeInsets.all(60),
                  child: Align(
                    alignment: Alignment.center,
                    child: cameraButton(context),
                  ),
                ),
                Positioned(bottom: 120, child: videoStatusAnimation),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Align buildFlashIcons() {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        onPressed: () {
          setState(() {
            currentFlashMode = currentFlashMode == Flash.off
                ? Flash.auto
                : (currentFlashMode == Flash.auto ? Flash.on : Flash.off);
          });
          currentFlashMode == Flash.on
              ? widget.controller.value.setFlashMode(FlashMode.torch)
              : currentFlashMode == Flash.off
                  ? widget.controller.value.setFlashMode(FlashMode.off)
                  : widget.controller.value.setFlashMode(FlashMode.auto);
        },
        icon: Icon(
            currentFlashMode == Flash.on
                ? Icons.flash_on_rounded
                : (currentFlashMode == Flash.auto
                    ? Icons.flash_auto_rounded
                    : Icons.flash_off_rounded),
            color: Colors.white),
      ),
    );
  }

  Align buildRotationIcon(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () async {
          if (widget.cameras!.value.length > 1) {
            setState(() {
              selectedCamera = selectedCamera == 0 ? 1 : 0;
              widget.onNewCameraSelected(selectedCamera, false);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(widget.tapsNames.notFoundingCameraText),
              duration: const Duration(seconds: 2),
            ));
          }
        },
        icon:
            const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
      ),
    );
  }

  CustomCrop buildCrop(File selectedImage) {
    return CustomCrop.file(
      selectedImage,
      key: cropKey,
      alwaysShowGrid: true,
      paintColor: widget.appTheme.primaryColor,
    );
  }

  AppBar appBar(BuildContext context) {
    Color whiteColor = widget.appTheme.primaryColor;
    Color blackColor = widget.appTheme.focusColor;
    File? selectedImage = widget.selectedCameraImage.value;
    return AppBar(
      backgroundColor: whiteColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.clear_rounded, color: blackColor, size: 30),
        onPressed: () {
          Navigator.of(context).maybePop();
        },
      ),
      actions: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          switchInCurve: Curves.easeIn,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                color: Colors.blue, size: 30),
            onPressed: () async {
              if (videoRecordFile != null) {
                SelectedImagesDetails details = SelectedImagesDetails(
                  selectedFile: videoRecordFile!,
                  multiSelectionMode: false,
                  isThatImage: false,
                  aspectRatio: 1.0,
                );
                widget.moveToPage(details);
              } else {
                if (selectedImage != null) {
                  File? croppedFile = await cropImage(selectedImage);
                  if (croppedFile != null) {
                    SelectedImagesDetails details = SelectedImagesDetails(
                      selectedFile: File(croppedFile.path),
                      multiSelectionMode: false,
                      aspectRatio: 1.0,
                    );
                    widget.moveToPage(details);
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Future<File?> cropImage(File imageFile) async {
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
  }

  GestureDetector cameraButton(BuildContext context) {
    Color whiteColor = widget.appTheme.primaryColor;
    return GestureDetector(
      onTap: widget.enableCamera ? onPress : null,
      onLongPress: widget.enableVideo ? onLongTap : null,
      onLongPressUp: widget.enableVideo ? onLongTapUp : onPress,
      child: CircleAvatar(
          backgroundColor: Colors.grey[400],
          radius: 40,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: whiteColor,
          )),
    );
  }

  onPress() async {
    try {
      if (!widget.selectedVideo) {
        final image = await widget.controller.value.takePicture();
        File selectedImage = File(image.path);

        /// To fix the orientation of the front camera
        if (selectedCamera == 1) {
          List<int> imageBytes = await selectedImage.readAsBytes();
          final originalImage = img.decodeImage(imageBytes);
          if (originalImage != null) {
            img.Image fixedImage;
            fixedImage = img.copyRotate(originalImage, -360);
            selectedImage =
                await selectedImage.writeAsBytes(img.encodeJpg(fixedImage));
          }
        }
        setState(() {
          widget.selectedCameraImage.value = selectedImage;
          widget.replacingTabBar(true);
        });
      } else {
        setState(() => videoStatusAnimation = buildFadeAnimation());
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  onLongTap() {
    widget.controller.value.startVideoRecording();
    widget.moveToVideoScreen();
    setState(() {
      startVideoCount.value = true;
    });
  }

  onLongTapUp() async {
    setState(() {
      startVideoCount.value = false;
      widget.replacingTabBar(true);
    });
    XFile w = await widget.controller.value.stopVideoRecording();
    videoRecordFile = File(w.path);
  }

  RecordFadeAnimation buildFadeAnimation() {
    return RecordFadeAnimation(child: buildMessage());
  }

  Widget buildMessage() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            color: Color.fromARGB(255, 54, 53, 53),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.tapsNames.holdButtonText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Center(
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: Color.fromARGB(255, 49, 49, 49),
              size: 65,
            ),
          ),
        ),
      ],
    );
  }
}
