import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// stands in for the thumbnail of a picked video, it has none.
class VideoTile extends StatelessWidget {
  const VideoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return ColoredBox(
      color: theme.surface,
      child: Center(child: Icon(Icons.videocam_outlined, color: theme.onSurfaceMuted)),
    );
  }
}
