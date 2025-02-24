import 'dart:async' show StreamController;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart';
import 'package:image_picker_plus/redesign_src/core/custom_state_management/state_selector.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_manager.dart';
import 'package:image_picker_plus/redesign_src/core/utils/edit_media_parameters.dart';
import 'package:image_picker_plus/redesign_src/core/utils/string_manager.dart';
import 'package:image_picker_plus/redesign_src/view_model/crop_image_view_model.dart';
import 'package:image_picker_plus/redesign_src/view_model/filter/filters.dart';
import 'package:image_picker_plus/redesign_src/widgets/adaptive_layout.dart';
import 'package:image_picker_plus/redesign_src/widgets/crop_image.dart';
import 'package:image_picker_plus/redesign_src/widgets/custom_expand_icon.dart';
import 'package:image_picker_plus/redesign_src/widgets/image_filters.dart';
import 'package:image_picker_plus/redesign_src/widgets/scale_popup_animation.dart';

part 'single_image_editor/single_image_editor_page.dart';
part 'single_image_editor/single_image_filters.dart';

class EditImagePage extends StatefulWidget {
  final EditImagePageParameters parameters;
  const EditImagePage({super.key, required this.parameters});

  @override
  State<EditImagePage> createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage> with AutomaticKeepAliveClientMixin {
  @override
  void dispose() {
    EditMediaViewModel.resetInstance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = EditMediaViewModel.getInstance().initializeParameters(parameters: widget.parameters);

    final fullImage = controller.singleImageFile;
    final fullImage2 = controller.singleImageImg;
    final isSingleImage = widget.parameters.originSelectedImage.length == 1;

    return PopScope(
      /// TODO: add this, or make user add them
      // canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        // if (didPop) return;
        //
        // final bool shouldPop = await controller.confirmDiscardAlert(context) ?? false;
        //
        // if (context.mounted && shouldPop) {
        //   widget.parameters.onImageEditedFinish(context, null);
        //   context.back(result: true);
        // }
      },
      child: isSingleImage
          ? _SingleEditImagePage(
              selectedImageIndex: 0,
              fullImage: fullImage,
              fullImage2: fullImage2,
              type: widget.parameters.type,
              selectedAspectRatio: ValueNotifier(controller.aspectRatio),
              selectedFilterIndex: ValueNotifier(
                controller.selectedFiltersIndex[0],
              ),
              selectedRotationAngle: ValueNotifier(
                controller.selectedRotation[0],
              ),
              onlyOneImage: true,
              nextText: widget.parameters.nextText,
            )
          : Scaffold(
              appBar: AppBar(actions: [_NextButton(widget.parameters.nextText)]),
              body: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                // shrinkWrap: true,
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      alignment: AlignmentDirectional.bottomStart,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.08,
                          child: _BuildImages(widget: widget),
                        ),
                        if (widget.parameters.type == CropEditImageType.normal)
                          _ExpandedIcon(
                            selectedAspect: widget.parameters.aspectRatio,
                            switchAspectRatio: () {
                              EditMediaViewModel.getInstance().switchAspectRatio();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: BuildFilters(
                        selectedFilterImageIndex: 0,
                        blurChild: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _BuildImages extends StatelessWidget {
  const _BuildImages({required this.widget});

  final EditImagePage widget;

  Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Opacity(opacity: 0.5, child: child);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditMediaViewModel.getInstance();

    return CustomStateSelector<EditMediaViewModel>(
      keys: [EditMediaViewModel.aspectRatioKey],
      controller: controller,
      builder: (context) {
        return ReorderableListView(
          /// to render the list of media to be able to crop it easy
          cacheExtent: 10000,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          onReorder: (oldIndex, newIndex) =>
              controller.updateReorderListView(oldIndex: oldIndex, newIndex: newIndex),
          proxyDecorator: proxyDecorator,
          footer: controller.allowForAddMoreImages
              ? _AddIcon(
                  onTap: () {
                    controller.addMoreImages(context);
                  },
                )
              : SizedBox(width: 10.r),
          children: List.generate(
            controller.croppedSelectedImage.length,
            (index) {
              return _BuildImageItem(
                key: UniqueKey(),
                widget: widget,
                controller: controller,
                index: index,
              );
            },
          ),
        );
      },
    );
  }
}

class _ExpandedIcon extends StatefulWidget {
  const _ExpandedIcon({
    required this.switchAspectRatio,
    required this.selectedAspect,
  });

  final VoidCallback switchAspectRatio;
  final double selectedAspect;
  @override
  State<_ExpandedIcon> createState() => _ExpandedIconState();
}

class _ExpandedIconState extends State<_ExpandedIcon> {
  bool isExpanded = true;
  @override
  void initState() {
    isExpanded = widget.selectedAspect == 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomExpandIcon(
      isExpanded: isExpanded,
      onTap: () {
        widget.switchAspectRatio();
        setState(() {
          isExpanded = !isExpanded;
        });
      },
    );
  }
}

class _RotateIconButton extends StatelessWidget {
  const _RotateIconButton({required this.nextRotation});
  final Future<void> Function() nextRotation;

  @override
  Widget build(BuildContext context) {
    final child = IconCircleAvatar(
      withInternalPadding: true,
      child: const _RotateIcon(),
      onTap: () async {
        try {
          await nextRotation();
        } catch (e) {
          debugPrint("========> something went in _RotateIconButton $e");
          if (context.mounted) {
            /// TODO:
            // context.toast(StringsManager.somethingWentWrong, type: wentWrongToastType);
          }
        }
      },
    );

    return child;
  }
}

class _RotateIcon extends StatelessWidget {
  const _RotateIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: true,
      child: Icon(
        Icons.rotate_right,
        color: context.getColor(ThemeEnum.primaryColor),
      ),

      /// TODO: add this

      // child: const CustomAssetsSvg(
      //   IconsAssets.basicRotate,
      //   color: ThemeEnum.primaryColor,
      // ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton(this.nextText);
  final String nextText;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStatePropertyAll(
                context.getColor(ThemeEnum.transparentColor),
              ),
            ),
            onPressed: () async {
              EditMediaViewModel.getInstance().onTapNext(context);
            },
            child: Text(
              nextText,
              style: TextStyle(
                color: context.getColor(ThemeEnum.blueColor),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildImageItem extends StatefulWidget {
  const _BuildImageItem({
    super.key,
    required this.index,
    required this.widget,
    required this.controller,
  });

  final EditImagePage widget;
  final int index;
  final EditMediaViewModel controller;

  @override
  State<_BuildImageItem> createState() => _BuildImageItemState();
}

class _BuildImageItemState extends State<_BuildImageItem> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Material(
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: 30.r, start: widget.index == 0 ? 20.r : 10.r),
        child: AspectRatio(
          aspectRatio: widget.controller.aspectRatio,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => _SingleEditImagePage(
                    isSingleAppliedImage: true,
                    type: widget.widget.parameters.type,
                    selectedImageIndex: widget.index,
                    fullImage: widget.widget.parameters.originSelectedImage[widget.index],
                    fullImage2: widget.widget.parameters.originSelectedImg[widget.index],
                    selectedAspectRatio: ValueNotifier(widget.controller.aspectRatio),
                    selectedFilterIndex: ValueNotifier(
                      widget.controller.selectedFiltersIndex[widget.index],
                    ),
                    selectedRotationAngle: ValueNotifier(
                      widget.controller.selectedRotation[widget.index],
                    ),
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: context.getColor(ThemeEnum.whiteD3Color),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    _BuildMainImage(
                      index: widget.index,
                      type: widget.widget.parameters.type,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: () {
                          EditMediaViewModel.getInstance().removeSpecificItem(widget.index);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.close,
                            size: 15.r,
                            color: context.getColor(ThemeEnum.whiteColor),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _AddIcon extends StatelessWidget {
  const _AddIcon({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: context.getColor(ThemeEnum.hintColor),
              width: 2.r,
            ),
          ),
          padding: EdgeInsets.all(25.r),
          child: const Icon(Icons.add, size: 40),

          /// TODO: add this
          // child: const CustomAssetsSvg(IconsAssets.add3, size: 40),
        ),
      ),
    );
  }
}

class _BuildMainImage extends StatelessWidget {
  const _BuildMainImage({required this.index, required this.type});

  final int index;
  final CropEditImageType type;

  @override
  Widget build(BuildContext context) {
    final controller = EditMediaViewModel.getInstance();

    return CustomStateSelector<EditMediaViewModel>(
      keys: [EditMediaViewModel.aspectRatioKey],
      controller: controller,
      builder: (context) {
        return AspectRatio(
          aspectRatio: controller.aspectRatio,
          child: _BuildImageFile(
            type: type,
            index: index,
            aspectRatio: controller.aspectRatio,
          ),
        );
      },
    );
  }
}

class _BuildImageFile extends StatefulWidget {
  const _BuildImageFile({
    required this.index,
    required this.aspectRatio,
    required this.type,
  });

  final int index;
  final double aspectRatio;
  final CropEditImageType type;

  @override
  State<_BuildImageFile> createState() => _BuildImageFileState();
}

class _BuildImageFileState extends State<_BuildImageFile> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = EditMediaViewModel.getInstance();

    return CustomStateSelector<EditMediaViewModel>(
      keys: [EditMediaViewModel.selectedFilterId(widget.index)],
      controller: controller,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomCropper(
              type: widget.type,
              enableInteract: false,
              rotateAngle: controller.selectedRotation[widget.index],
              image: controller.croppedSelectedImage[widget.index],
              aspectRatio: widget.aspectRatio,
              key: controller.getImageKey(widget.index),
              initialBoundaries: constraints.biggest,
              colorMatrix: controller.getSelectedFilterMatrix(imageIndex: widget.index),
              paintColor: context.getColor(ThemeEnum.primaryColor),
              gridColor: context.getColor(ThemeEnum.whiteD7Color),
              overlayColor: context.getColor(ThemeEnum.cropGreyOp25),
              isCroppingReady: controller.setCroppingReady,
            );
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
