import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart';
import 'package:image_picker_plus/redesign_src/core/custom_state_management/state_selector.dart';
import 'package:image_picker_plus/redesign_src/core/utils/color/theme_manager.dart';
import 'package:image_picker_plus/redesign_src/view_model/crop_image_view_model.dart';
import 'package:image_picker_plus/redesign_src/view_model/filter/filters.dart';
import 'package:image_picker_plus/redesign_src/widgets/scale_popup_animation.dart';

class BuildFilters extends StatelessWidget {
  const BuildFilters({
    super.key,
    this.blurChild = false,
    required this.selectedFilterImageIndex,
    this.child,
  });

  final int selectedFilterImageIndex;
  final bool blurChild;
  final Widget Function(int index)? child;

  @override
  Widget build(BuildContext context) {
    final r10 = 10.r;
    final child = this.child;
    return SizedBox(
      height: 150.r,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: Filters.list.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsetsDirectional.only(start: index == 0 ? r10 : 0, end: r10),
            child: child != null
                ? child(index)
                : _BuildSmallFilteredImage(
                    index: index,
                    blurChild: blurChild,
                    selectedFilterImageIndex: selectedFilterImageIndex,
                  ),
          );
        },
      ),
    );
  }
}

class _BuildSmallFilteredImage extends StatefulWidget {
  const _BuildSmallFilteredImage({
    required this.index,
    required this.blurChild,
    required this.selectedFilterImageIndex,
  });

  final int index;
  final int selectedFilterImageIndex;
  final bool blurChild;

  @override
  State<_BuildSmallFilteredImage> createState() => _BuildSmallFilteredImageState();
}

class _BuildSmallFilteredImageState extends State<_BuildSmallFilteredImage> {
  bool startTap = false;
  @override
  Widget build(BuildContext context) {
    final filter = Filters.list[widget.index];
    final controller = EditMediaViewModel.getInstance();

    return Listener(
      onPointerDown: (details) {
        setState(() {
          startTap = true;
        });
      },
      onPointerUp: (details) {
        setState(() {
          startTap = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          EditMediaViewModel.getInstance().changeAllSelectedImagesFilters(widget.index);
        },
        child: ScalePopupAnimationWidget(
          scaleBigger: false,
          isAnimating: startTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomStateSelector<EditMediaViewModel>(
                keys: [EditMediaViewModel.selectedFilterId(widget.selectedFilterImageIndex)],
                controller: EditMediaViewModel.getInstance(),
                builder: (context) {
                  return Text(
                    filter.filterName,
                    style: TextStyle(
                        fontSize: 12,
                        color: context.getColor(
                          controller.selectedFiltersIndex.contains(widget.index)
                              ? ThemeEnum.focusColor
                              : ThemeEnum.hoverColor,
                        ),
                        fontWeight: FontWeight.w500),
                  );
                },
              ),
              SizedBox(height: 5.r),
              widget.blurChild
                  ? SizedBox(
                      width: 90.r,
                      height: 90.r,
                      child: _SmallFilteredImageWithBlur(
                        selectedFilterImageIndex: widget.selectedFilterImageIndex,
                        index: widget.index,
                      ),
                    )
                  : SizedBox(
                      width: 90.r,
                      height: 90.r,
                      child: SmallFilteredImage(
                        selectedFilterImageIndex: widget.selectedFilterImageIndex,
                        index: widget.index,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmallFilteredImage extends StatelessWidget {
  const SmallFilteredImage({
    super.key,
    required this.selectedFilterImageIndex,
    required this.index,
  });

  final int selectedFilterImageIndex;
  final int index;

  @override
  Widget build(BuildContext context) {
    final controller = EditMediaViewModel.getInstance();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(Filters.list[index].matrix),
        child: CustomStateSelector<EditMediaViewModel>(
          controller: EditMediaViewModel.getInstance(),
          builder: (context) {
            return Image.file(
              controller.selectedImage[selectedFilterImageIndex],
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}

class _SmallFilteredImageWithBlur extends StatelessWidget {
  const _SmallFilteredImageWithBlur({
    required this.selectedFilterImageIndex,
    required this.index,
  });

  final int selectedFilterImageIndex;
  final int index;

  @override
  Widget build(BuildContext context) {
    String filterName = Filters.list[index].filterName;
    if (filterName.isNotEmpty) filterName = filterName[0];
    final controller = EditMediaViewModel.getInstance();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: CustomStateSelector<EditMediaViewModel>(
        controller: EditMediaViewModel.getInstance(),
        builder: (context) {
          return Stack(
            alignment: AlignmentDirectional.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.matrix(Filters.list[index].matrix),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(controller.selectedImage[selectedFilterImageIndex]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0, tileMode: TileMode.mirror),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black54.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                filterName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ],
          );
        },
      ),
    );
  }
}
