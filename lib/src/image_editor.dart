import 'dart:io';
import 'package:custom_gallery_display/custom_gallery_display.dart';
import 'package:custom_gallery_display/src/utilities/filters.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ImageEditor extends StatefulWidget {
  final File? selectedImage;
  final AppTheme appTheme;
  final ValueNotifier<TabController> editViewTabController;
  final ValueNotifier<int> indexOfFilter;
  final Color whiteColor;

  const ImageEditor({
    Key? key,
    required this.selectedImage,
    required this.appTheme,
    required this.editViewTabController,
    required this.indexOfFilter,
    required this.whiteColor,
  }) : super(key: key);

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Material(color: widget.whiteColor, child: buildImageEditor()));
  }

  Widget buildImageEditor() {
    return ValueListenableBuilder(
      valueListenable: widget.editViewTabController,
      builder: (context, TabController tabControllerValue, child) => Container(
        color: widget.whiteColor == Colors.white
            ? const Color.fromARGB(255, 250, 250, 250)
            : widget.whiteColor,
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
    );
  }

  Container editTabBarView(BuildContext context) {
    return Container(
        color: Colors.green, width: MediaQuery.of(context).size.width);
  }

  Widget filterTabBarView(BuildContext context) {
    return ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return buildImages(index);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: filters.length);
  }

  Widget buildImages(int index) {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => widget.indexOfFilter.value = index),
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
              child: widget.selectedImage != null
                  ? ColorFiltered(
                      colorFilter: ColorFilter.matrix(filters[index]),
                      child: Image.file(
                        widget.selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // height: 90,
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}
