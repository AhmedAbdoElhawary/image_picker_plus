import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:image_picker_plus/src/gallery_display.dart';
import 'package:image_picker_plus/src/utilities/enum.dart';
import 'package:flutter/material.dart';

class ImagePickerPlus {
  final BuildContext _context;
  ImagePickerPlus(this._context);

  Future<SelectedImagesDetails?> pickImage({
    required ImageSource source,
    GalleryDisplaySettings? galleryDisplaySettings,
    bool multiImages = false,
  }) async {
    return _pushToCustomPicker(
      galleryDisplaySettings: galleryDisplaySettings,
      multiSelection: multiImages,
      pickerSource: PickerSource.image,
      source: source,
    );
  }

  Future<SelectedImagesDetails?> pickVideo({
    required ImageSource source,
    GalleryDisplaySettings? galleryDisplaySettings,
    bool multiVideos = false,
  }) async {
    return _pushToCustomPicker(
      galleryDisplaySettings: galleryDisplaySettings,
      multiSelection: multiVideos,
      pickerSource: PickerSource.video,
      source: source,
    );
  }

  Future<SelectedImagesDetails?> pickBoth({
    required ImageSource source,
    GalleryDisplaySettings? galleryDisplaySettings,
    bool multiSelection = false,
    bool byDate = false,
  }) async {
    return _pushToCustomPicker(
      galleryDisplaySettings: galleryDisplaySettings,
      multiSelection: multiSelection,
      byDate: byDate,
      pickerSource: PickerSource.both,
      source: source,
    );
  }

  Future<SelectedImagesDetails?> _pushToCustomPicker({
    required ImageSource source,
    GalleryDisplaySettings? galleryDisplaySettings,
    bool multiSelection = false,
    bool byDate = false,
    required PickerSource pickerSource,
  }) async {
    return await Navigator.of(_context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => CustomImagePicker(
          galleryDisplaySettings: galleryDisplaySettings,
          multiSelection: multiSelection,
          byDate: byDate,
          pickerSource: pickerSource,
          source: source,
        ),
        maintainState: false,
      ),
    );
  }
}
