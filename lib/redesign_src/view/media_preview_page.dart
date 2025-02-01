import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/custom_state_management/state_selector.dart';
import 'package:image_picker_plus/redesign_src/view_model/media_preview_view_model.dart';

class MediaPreviewPage extends StatelessWidget {
  const MediaPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final itemsCount = 120;
    final previewHeight = MediaPreviewViewModel.getPreviewHeight(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                MediaPreviewViewModel().handlePreviewPosition(context, notification);
                return true;
              },
              child: CustomScrollView(
                slivers: [
                  /// this is static for all screens as the preview height is the same width,

                  SliverToBoxAdapter(child: SizedBox(height: previewHeight)),

                  SliverGrid.builder(
                    itemCount: itemsCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 2.5,
                      mainAxisSpacing: 2.5,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        color: Colors.green,
                        child: Center(child: Text(index.toString())),
                      );
                    },
                  ),
                ],
              ),
            ),
            _BuildPreview(),
          ],
        ),
      ),
    );
  }
}

class _BuildPreview extends StatelessWidget {
  const _BuildPreview();

  @override
  Widget build(BuildContext context) {
    final previewHeight = MediaPreviewViewModel.getPreviewHeight(context);
    final width = MediaQuery.sizeOf(context).width;
    return CustomStateSelector<MediaPreviewViewModel>(
      keys: [MediaPreviewViewModel.currentTopHidePreviewPositionId],
      state: MediaPreviewViewModel(),
      builder: (context) {
        return AnimatedPositioned(
          duration: Duration(milliseconds: MediaPreviewViewModel().makeAnimatedPosition ? 300 : 0),
          top: MediaPreviewViewModel().currentTopHidePreviewPosition,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: previewHeight,
                  color: Colors.white,
                  child: Image.network(
                    "https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885_1280.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
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
                      IconButton(
                          onPressed: () {
                            MediaPreviewViewModel().showPreviewFully(context);
                          },
                          icon: Icon(Icons.copy_rounded)),
                      Icon(Icons.camera),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}