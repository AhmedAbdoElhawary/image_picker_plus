import 'dart:io';

class SelectedImagesDetails {
  List<SelectedByte> selectedBytes;
  double aspectRatio;
  bool multiSelectionMode;

  SelectedImagesDetails({
    required this.selectedBytes,
    required this.aspectRatio,
    required this.multiSelectionMode,
  });
}

class SelectedByte {
  File selectedByte;
  bool isThatImage;
  SelectedByte({required this.isThatImage, required this.selectedByte});
}
