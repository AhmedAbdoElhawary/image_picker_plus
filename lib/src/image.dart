import 'dart:typed_data';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:flutter/material.dart';

class MemoryImageDisplay extends StatelessWidget {
  final Uint8List imageBytes;
  final AppTheme appTheme;

  const MemoryImageDisplay({super.key, required this.imageBytes, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    precacheImage(MemoryImage(imageBytes), context);

    return Container(
      width: double.infinity,
      color: appTheme.shimmerBaseColor,
      child: Image.memory(
        imageBytes,
        errorBuilder: (context, url, error) => _ErrorWidget(widget: this),
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.widget});

  final MemoryImageDisplay widget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity, child: Icon(Icons.warning_amber_rounded, color: widget.appTheme.focusColor));
  }
}
