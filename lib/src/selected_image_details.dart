import 'dart:io';

class SelectedImageDetails {
  File selectedFile;
  List<File>? selectedFiles;
  bool isThatImage;
  double aspectRatio;
  bool multiSelectionMode;

  SelectedImageDetails({
    this.selectedFiles,
    this.isThatImage = true,
    required this.aspectRatio,
    required this.selectedFile,
    required this.multiSelectionMode,
  });
}
