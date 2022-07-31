import 'dart:typed_data';
import 'package:custom_gallery_display/custom_gallery_display.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

class MemoryImageDisplay extends StatefulWidget {
  final Uint8List imageFile;
  final AppTheme appTheme;

  const MemoryImageDisplay(
      {Key? key, required this.imageFile, required this.appTheme})
      : super(key: key);

  @override
  State<MemoryImageDisplay> createState() => _NetworkImageDisplayState();
}

class _NetworkImageDisplayState extends State<MemoryImageDisplay> {
  @override
  void didChangeDependencies() {
    precacheImage(MemoryImage(widget.imageFile), context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return buildOctoImage();
  }

  OctoImage buildOctoImage() {
    return OctoImage(
      image: MemoryImage(widget.imageFile),
      errorBuilder: (context, url, error) => buildError(),
      fit: BoxFit.cover,
      width: double.infinity,
      placeholderBuilder: (context) => Center(child: buildSizedBox()),
    );
  }

  SizedBox buildError() {
    return SizedBox(
        width: double.infinity,
        child: Icon(Icons.warning_amber_rounded,
            size: 50, color: widget.appTheme.focusColor));
  }

  Widget buildSizedBox() {
    return Container(
      width: double.infinity,
      color: widget.appTheme.shimmerBaseColor,
    );
  }
}
