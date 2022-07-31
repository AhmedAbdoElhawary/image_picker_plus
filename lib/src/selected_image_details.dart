import 'dart:io';

class SelectedImagesDetails {
  File selectedFile;
  List<File>? selectedFiles;
  bool isThatImage;
  double aspectRatio;
  bool multiSelectionMode;

  SelectedImagesDetails({
    this.selectedFiles,
    this.isThatImage = true,
    required this.aspectRatio,
    required this.selectedFile,
    required this.multiSelectionMode,
  });
}
