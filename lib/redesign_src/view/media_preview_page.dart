import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart'
    show ScreenSizeHelper, SizeHelper, SizeIntHelper;
import 'package:image_picker_plus/redesign_src/core/custom_state_management/state_selector.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/color_manager.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_adaptation.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_manager.dart';
import 'package:image_picker_plus/redesign_src/core/utils/string_manager.dart';
import 'package:image_picker_plus/redesign_src/view_model/filter/filters.dart';
import 'package:image_picker_plus/redesign_src/view_model/media_preview_view_model.dart';
import 'package:image_picker_plus/redesign_src/widgets/crop_image.dart' show CropEditImageType, CustomCropper;

class MediaPreviewPage extends StatefulWidget {
  const MediaPreviewPage({super.key});

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  @override
  void dispose() {
    MediaPreviewViewModel.resetInstance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSizeHelper().initializeScreenSize(context);
    ThemeAdaptation().initializeScreenSize = true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
              onPressed: () async {
                // final file = MediaPreviewViewModel.getInstance().selectedMedia;
                // if (file == null) return;
                // final files = [file];
                // final returnData = await Conversions.convertMultiFilesToImg(files);
                // if (returnData == null) return;
                // final listOfZeros = List.generate(files.length, (index) => 0);
                //
                // context.push(
                //   EditImagePage(
                //     parameters: EditImagePageParameters(
                //       // type: type,
                //       tempCacheSessionUUid: RandomString.generate(),
                //       originSelectedImg: returnData,
                //       maxImageSelected: 10,
                //       croppedSelectedImage: files,
                //       originSelectedImage: files,
                //       selectedFilersIndexes: listOfZeros,
                //       selectedRotation: listOfZeros,
                //       onImageEditedFinish: (context, par) {},
                //       // resizeHeight: maxHeight,
                //       // resizeWidth: maxWidth,
                //       // nextText: saveEditText,
                //     ),
                //   ),
                // );
              },
              child: Text(StringsManager.next))
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            _BuildMediaGrid(),
            _BuildPreview(),
          ],
        ),
      ),
    );
  }
}

class _BuildMediaGrid extends StatelessWidget {
  const _BuildMediaGrid();

  @override
  Widget build(BuildContext context) {
    final previewHeight = MediaPreviewViewModel.getPreviewHeight();

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        MediaPreviewViewModel.getInstance().handlePreviewPosition(notification.metrics.pixels);
        return true;
      },
      child: CustomScrollView(
        controller: MediaPreviewViewModel.getInstance().scrollController,
        slivers: [
          /// this is static for all screens as the preview height is the same width,
          SliverToBoxAdapter(child: SizedBox(height: previewHeight + kToolbarHeight)),

          _BuildGridView(),
        ],
      ),
    );
  }
}

class _BuildGridView extends StatelessWidget {
  const _BuildGridView();

  @override
  Widget build(BuildContext context) {
    final isTablet = ScreenSizeHelper().isTablet;
    final controller = MediaPreviewViewModel.getInstance();

    return CustomStateSelector<MediaPreviewViewModel>(
      keys: [MediaPreviewViewModel.loadedMediaId],
      controller: MediaPreviewViewModel.getInstance(),
      builder: (context) {
        final loadedMedia = controller.loadedMedia;
        return SliverGrid.builder(
          itemCount: loadedMedia.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 5 : 4,
            crossAxisSpacing: 2.5,
            mainAxisSpacing: 2.5,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return RepaintBoundary(child: _BuildSingleGridItem(loadedMedia[index]));
          },
        );
      },
    );
  }
}

class _BuildSingleGridItem extends StatelessWidget {
  const _BuildSingleGridItem(this.file);
  final File? file;

  @override
  Widget build(BuildContext context) {
    final file = this.file;
    if (file == null) return SizedBox();
    final controller = MediaPreviewViewModel.getInstance();

    return InkWell(
      onTap: () {
        controller.addSingleSelectedMedia = file;
      },
      onLongPress: () {
        controller
          ..allowMultiSelection = true
          ..addSingleSelectedMedia = file;
      },
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, cons) {
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  cacheWidth: cons.maxWidth.toInt(),
                  cacheHeight: cons.maxHeight.toInt(),
                ),
              );
            },
          ),
          CustomStateSelector<MediaPreviewViewModel>(
            keys: [MediaPreviewViewModel.selectedBlurSingleMediaId(file.path)],
            controller: controller,
            builder: (context) {
              return controller.currentSelectedMedia?.path == file.path
                  ? Container(color: Colors.white24)
                  : SizedBox();
            },
          ),
          CustomStateSelector<MediaPreviewViewModel>(
            keys: [MediaPreviewViewModel.allowMultiSelectionId],
            controller: controller,
            builder: (context) {
              return controller.allowMultiSelection ? _CircleSelection(file) : SizedBox();
            },
          ),
        ],
      ),
    );
  }
}

class _CircleSelection extends StatelessWidget {
  const _CircleSelection(this.file);
  final File file;

  @override
  Widget build(BuildContext context) {
    final controller = MediaPreviewViewModel.getInstance();

    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: Padding(
        padding: EdgeInsets.all(5.r),
        child: CustomStateSelector<MediaPreviewViewModel>(
          keys: [MediaPreviewViewModel.selectedIndexSingleMediaId(file.path)],
          controller: MediaPreviewViewModel.getInstance(),
          builder: (context) {
            final number = controller.getNumberOfSelectedMedia(file);

            final isSelected = number != 0;

            return Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                  color: isSelected
                      ? context.getColor(ThemeEnum.blueColor)
                      : context.getColor(ThemeEnum.primaryColor).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.getColor(ThemeEnum.primaryColor), width: 1.5.r)),
              child: isSelected
                  ? Center(
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          color: context.getColor(ThemeEnum.primaryColor),
                          fontWeight: FontWeight.w500,
                          fontSize: 16.r,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _BuildPreview extends StatelessWidget {
  const _BuildPreview();

  @override
  Widget build(BuildContext context) {
    final controller = MediaPreviewViewModel.getInstance();
    return CustomStateSelector<MediaPreviewViewModel>(
      keys: [MediaPreviewViewModel.currentTopHidePreviewPositionId],
      controller: MediaPreviewViewModel.getInstance(),
      builder: (context) {
        return AnimatedPositioned(
          duration: Duration(milliseconds: controller.makeAnimatedPosition ? 200 : 0),
          top: controller.currentTopHidePreviewPosition,
          child: _BuildPreviewMiddleBar(),
        );
      },
    );
  }
}

class _BuildPreviewMiddleBar extends StatelessWidget {
  const _BuildPreviewMiddleBar();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BuildSelectedMedia(),
          _BuildMiddleBar(width: width),
        ],
      ),
    );
  }
}

class _BuildMiddleBar extends StatelessWidget {
  const _BuildMiddleBar({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final controller = MediaPreviewViewModel.getInstance();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: controller.appearPreview,
      child: Container(
        height: kToolbarHeight,
        color: Colors.white,
        width: width,
        padding: EdgeInsetsDirectional.symmetric(horizontal: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(StringsManager.recent),
            const Spacer(),
            _MultiSelectionIcon(),
            SizedBox(width: 15),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: ColorManager.blackOp40,
                child: Icon(Icons.camera, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectionIcon extends StatelessWidget {
  const _MultiSelectionIcon();

  @override
  Widget build(BuildContext context) {
    final controller = MediaPreviewViewModel.getInstance();

    return InkWell(
      onTap: () {
        controller.allowMultiSelection = !controller.allowMultiSelection;
      },
      borderRadius: BorderRadius.circular(50),
      child: CustomStateSelector<MediaPreviewViewModel>(
        keys: [MediaPreviewViewModel.allowMultiSelectionId],
        controller: controller,
        builder: (context) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: controller.allowMultiSelection ? ColorManager.blue : ColorManager.blackOp40,
            child: Icon(Icons.copy_rounded, color: Colors.white),
          );
        },
      ),
    );
  }
}

class _BuildSelectedMedia extends StatelessWidget {
  const _BuildSelectedMedia();

  @override
  Widget build(BuildContext context) {
    final previewHeight = MediaPreviewViewModel.getPreviewHeight();
    final width = MediaQuery.sizeOf(context).width;
    final controller = MediaPreviewViewModel.getInstance();

    return Container(
      height: previewHeight,
      width: width,
      color: Colors.white,
      child: CustomStateSelector<MediaPreviewViewModel>(
        keys: [MediaPreviewViewModel.selectedMediaId],
        controller: MediaPreviewViewModel.getInstance(),
        builder: (context) {
          final selectedMedia = controller.currentSelectedMedia;

          final selectedMediaKey = controller.getCurrentCropKey();

          return selectedMedia == null
              ? SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    /// TODO: handle those static parameters
                    return CustomCropper(
                      type: CropEditImageType.normal,
                      enableInteract: true,
                      rotateAngle: 0,
                      image: selectedMedia,
                      aspectRatio: 1,
                      key: selectedMediaKey,
                      initialBoundaries: constraints.biggest,
                      colorMatrix: Filters.list[0].matrix,
                      paintColor: context.getColor(ThemeEnum.primaryColor),
                      gridColor: context.getColor(ThemeEnum.whiteD7Color),
                      overlayColor: context.getColor(ThemeEnum.cropGreyOp25),
                      isCroppingReady: (value) {
                        print("++_+_+_+_+_+  ${value}");
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}
