import 'dart:io';

import 'package:flutter/foundation.dart';

class SelectedImagesDetails {
  List<SelectedByte> selectedFiles;
  double aspectRatio;
  bool multiSelectionMode;

  SelectedImagesDetails({
    required this.selectedFiles,
    required this.aspectRatio,
    required this.multiSelectionMode,
  });
}

class SelectedByte {
  File selectedFile;
  Uint8List selectedByte;

  bool isThatImage;
  SelectedByte({
    required this.isThatImage,
    required this.selectedFile,
    required this.selectedByte,
  });
}
