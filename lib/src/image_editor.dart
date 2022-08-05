import 'dart:io';
import 'dart:typed_data';
import 'package:custom_gallery_display/custom_gallery_display.dart';
import 'package:custom_gallery_display/src/customPackages/crop_image/crop_image.dart';
import 'package:custom_gallery_display/src/customPackages/crop_image/crop_options.dart';
import 'package:custom_gallery_display/src/filters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

typedef CropImageWidget = Widget Function(File selectedImage, bool expandImage);
typedef CropImageCallback = Future<File?> Function(File selectedImage);

class ImageEditor extends StatefulWidget {
  final Uint8List selectedImage;
  final SelectedImagesDetails details;
  final AsyncValueSetter<SelectedImagesDetails> sendRequestFunction;
  final AppTheme appTheme;
  // final CropImageWidget cropImageWidget;
  // final CropImageCallback cropImageCallback;

  const ImageEditor({
    Key? key,
    required this.sendRequestFunction,
    // required this.cropImageCallback,
    // required this.cropImageWidget,
    required this.selectedImage,
    required this.appTheme,
    required this.details,
  }) : super(key: key);

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor>
    with TickerProviderStateMixin {
  late ValueNotifier<TabController> tabController;
  final expandImage = ValueNotifier(false);
  final ValueNotifier<List<GlobalKey>> _globalKes = ValueNotifier([]);
  final ValueNotifier<GlobalKey> _globalKey = ValueNotifier(GlobalKey());

  final ValueNotifier<int> indexOfFilter = ValueNotifier(0);

  final cropKey = GlobalKey<CropState>();
  late Color whiteColor;
  late Color blackColor;

  @override
  void initState() {
    tabController = ValueNotifier(TabController(length: 2, vsync: this));
    whiteColor = widget.appTheme.primaryColor;
    blackColor = widget.appTheme.focusColor;
    super.initState();
  }

  @override
  void dispose() {
    expandImage.dispose();
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Column(
        children: [
          showSelectedImage(),
          Flexible(
            child: DefaultTabController(
                length: 2,
                child: Material(color: whiteColor, child: safeArea())),
          ),
        ],
      ),
    );
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
                  Container(
                color: whiteColor == Colors.white
                    ? const Color.fromARGB(255, 250, 250, 250)
                    : whiteColor,
                child: TabBarView(
                  controller: tabControllerValue,
                  dragStartBehavior: DragStartBehavior.start,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    filterTabBarView(context),
                    editTabBarView(context),
                  ],
                ),
              ),
            ),
          ),
          tabBar(),
        ],
      ),
    );
  }

  Widget filterTabBarView(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _globalKes,
      builder: (context, List<GlobalKey> globalKesValue, child) =>
          ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (index == 0) _globalKes.value.clear();
                if (globalKesValue.length <= index) {
                  _globalKes.value.add(GlobalKey());
                }
                return buildImages(index);
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: filters.length),
    );
  }

  void convertWidgetToImage(int index) async {
    File image = File.fromRawPath(widget.selectedImage);
    File? croppedImage = await cropImage(image);
    if (croppedImage != null) {
      RenderRepaintBoundary? repaintBoundary = _globalKey.value.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      ui.Image? boxImage = await repaintBoundary?.toImage(pixelRatio: 10);
      ByteData? byteData =
          await boxImage?.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? image = byteData?.buffer.asUint8List();
      Navigator.of(_globalKey.value.currentContext!).push(MaterialPageRoute(
          builder: (context) => SecondScreen(imageData: image!)));
    }
  }

  Widget buildImages(int index) {
    return Center(
      child: ValueListenableBuilder(
        valueListenable: _globalKes,
        builder: (context, List<GlobalKey> globalKeysValue, child) =>
            GestureDetector(
          onTap: () => setState(() => indexOfFilter.value = index),
          child: SizedBox(
            height: 80,
            width: 90,
            child: Padding(
              padding: EdgeInsets.only(
                  left: index == 0 ? 8.0 : 0,
                  right: index == filters.length - 1 ? 8.0 : 0),
              child: Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(255, 194, 194, 194),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(filters[index]),
                  child: Image.memory(
                    widget.selectedImage,
                    fit: BoxFit.cover,

                    width: double.infinity,
                    // height: 90,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container editTabBarView(BuildContext context) {
    return Container(
        color: Colors.green, width: MediaQuery.of(context).size.width);
  }

  Widget tabBar() {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: tabController,
                builder: (context, TabController tabControllerValue, child) =>
                    TabBar(
                  indicatorWeight: 1,
                  controller: tabControllerValue,
                  unselectedLabelColor: Colors.grey,
                  labelColor: blackColor,
                  indicatorColor: blackColor,
                  labelPadding: const EdgeInsets.all(13),
                  tabs: const [Text("FILTER"), Text("EDIT")],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: whiteColor,
      elevation: 0,
      centerTitle: true,
      title: Icon(Icons.edit_off_rounded, color: blackColor),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: blackColor),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: indexOfFilter,
          builder: (context, int indexOfFilterValue, child) =>
              ValueListenableBuilder(
            valueListenable: _globalKes,
            builder: (context, List<GlobalKey> globalKeysValue, child) =>
                IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.blue),
              onPressed: () async {
                convertWidgetToImage(indexOfFilterValue);
                // widget.details.selectedBytes =i!;
                // widget.sendRequestFunction(widget.details);
              },
            ),
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

  Widget showSelectedImage() {
    double width = MediaQuery.of(context).size.width;
    return Container(
      key: GlobalKey(debugLabel: "have image"),
      color: whiteColor,
      height: 360,
      width: width,
      child: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: indexOfFilter,
            builder: (context, int indexOfFilterValue, child) =>
                ValueListenableBuilder(
              valueListenable: expandImage,
              builder: (context, bool expandImageValue, child) => Crop.memory(
                widget.selectedImage,
                key: cropKey,
                paintColor: widget.appTheme.primaryColor,
                aspectRatio: expandImageValue ? 6 / 8 : 1.0,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: () =>
                    setState(() => expandImage.value = !expandImage.value),
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
}

class SecondScreen extends StatelessWidget {
  final Uint8List imageData;

  const SecondScreen({Key? key, required this.imageData}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints:
              BoxConstraints(maxHeight: size.width, maxWidth: size.width),
          child: Image.memory(
            imageData,
            width: size.width,
            height: size.height,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
