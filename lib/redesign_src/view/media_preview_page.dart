import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart'
    show ScreenSizeHelper;
import 'package:image_picker_plus/redesign_src/core/custom_state_management/state_selector.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_adaptation.dart';
import 'package:image_picker_plus/redesign_src/core/utils/context_extension.dart';
import 'package:image_picker_plus/redesign_src/core/utils/conversions.dart';
import 'package:image_picker_plus/redesign_src/core/utils/edit_media_parameters.dart';
import 'package:image_picker_plus/redesign_src/core/utils/random_text.dart';
import 'package:image_picker_plus/redesign_src/view/edit_media_page.dart';
import 'package:image_picker_plus/redesign_src/view_model/media_preview_view_model.dart';

class MediaPreviewPage extends StatelessWidget {
  const MediaPreviewPage({super.key});

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
                final file = MediaPreviewViewModel().selectedMedia;
                if (file == null) return;
                final files = [file];
                final returnData = await Conversions.convertMultiFilesToImg(files);
                if (returnData == null) return;
                final listOfZeros = List.generate(files.length, (index) => 0);

                context.push(
                  EditImagePage(
                    parameters: EditImagePageParameters(
                      // type: type,
                      tempCacheSessionUUid: RandomString.generate(),
                      originSelectedImg: returnData,
                      maxImageSelected: 10,
                      croppedSelectedImage: files,
                      originSelectedImage: files,
                      selectedFilersIndexes: listOfZeros,
                      selectedRotation: listOfZeros,
                      onImageEditedFinish: (context, par) {},
                      // resizeHeight: maxHeight,
                      // resizeWidth: maxWidth,
                      // nextText: saveEditText,
                    ),
                  ),
                );
              },
              child: Text("Next"))
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
        MediaPreviewViewModel().handlePreviewPosition(notification.metrics.pixels);
        return true;
      },
      child: CustomScrollView(
        controller: MediaPreviewViewModel().scrollController,
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
    final controller = MediaPreviewViewModel();

    return CustomStateSelector<MediaPreviewViewModel>(
      keys: [MediaPreviewViewModel.loadedMediaId],
      controller: MediaPreviewViewModel(),
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
    final controller = MediaPreviewViewModel();

    return InkWell(
      onTap: () {
        MediaPreviewViewModel().selectedMedia = file;
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
          // MultiSelectionMode()
          CustomStateSelector<MediaPreviewViewModel>(
            keys: [file.path],
            controller: MediaPreviewViewModel(),
            builder: (context) {
              return controller.selectedMedia?.path == file.path
                  ? Container(color: Colors.white24)
                  : SizedBox();
            },
          )
        ],
      ),
    );
  }
}

class _BuildPreview extends StatefulWidget {
  const _BuildPreview();

  @override
  State<_BuildPreview> createState() => _BuildPreviewState();
}

class _BuildPreviewState extends State<_BuildPreview> {
  final GlobalKey _globalKey = GlobalKey();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MediaPreviewViewModel().detectMiddleBarPosition(_globalKey);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final controller = MediaPreviewViewModel();
    return CustomStateSelector<MediaPreviewViewModel>(
      keys: [MediaPreviewViewModel.currentTopHidePreviewPositionId],
      controller: MediaPreviewViewModel(),
      builder: (context) {
        return AnimatedPositioned(
          duration: Duration(milliseconds: controller.makeAnimatedPosition ? 200 : 0),
          top: controller.currentTopHidePreviewPosition,
          child: Listener(
            key: _globalKey,
            onPointerMove: controller.handleMiddleBarTapMove,
            onPointerUp: controller.handleMiddleBarTapEnd,
            child: _BuildMiddleBar(),
          ),
        );
      },
    );
  }
}

class _BuildMiddleBar extends StatelessWidget {
  const _BuildMiddleBar();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BuildSelectedMedia(),
          Container(
            height: kToolbarHeight,
            color: Colors.white,
            width: width,
            padding: EdgeInsetsDirectional.symmetric(horizontal: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Recent"),
                const Spacer(),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(50),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black38,
                    child: Icon(Icons.copy_rounded, color: Colors.white),
                  ),
                ),
                SizedBox(width: 15),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(50),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black38,
                    child: Icon(Icons.camera, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final controller = MediaPreviewViewModel();

    return Container(
      height: previewHeight,
      width: width,
      color: Colors.white,
      child: CustomStateSelector<MediaPreviewViewModel>(
        keys: [MediaPreviewViewModel.selectedMediaId],
        controller: MediaPreviewViewModel(),
        builder: (context) {
          final selectedMedia = controller.selectedMedia;
          return selectedMedia == null ? SizedBox() : Image.file(selectedMedia, fit: BoxFit.cover);
        },
      ),
    );
  }
}
