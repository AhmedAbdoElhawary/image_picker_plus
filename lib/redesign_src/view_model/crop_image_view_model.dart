import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/redesign_src/core/custom_state_management/base_custom_state.dart';
import 'package:image_picker_plus/redesign_src/core/utils/context_extension.dart';
import 'package:image_picker_plus/redesign_src/core/utils/conversions.dart';
import 'package:image_picker_plus/redesign_src/core/utils/edit_media_parameters.dart';
import 'package:image_picker_plus/redesign_src/core/utils/loading_screen.dart' show GeneralLoadingScreen;
import 'package:image_picker_plus/redesign_src/core/utils/string_manager.dart';
import 'package:image_picker_plus/redesign_src/view_model/filter/apply_filter_params.dart';
import 'package:image_picker_plus/redesign_src/view_model/filter/filter_manager.dart';
import 'package:image_picker_plus/redesign_src/view_model/filter/filters.dart';
import 'package:image_picker_plus/redesign_src/widgets/crop_image.dart';

class _CropImagePar {
  final img.Image srcImage;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final EditImagePageParameters parameters;

  _CropImagePar({
    required this.srcImage,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.parameters,
  });
}

class EditMediaViewModel extends BaseCustomState {
  EditMediaViewModel._internal();
  static EditMediaViewModel? _instance;
  static EditMediaViewModel getInstance() => _instance ??= EditMediaViewModel._internal();

  static void resetInstance() {
    _instance = null;
  }

  // State update keys
  static String selectedFilterId(int index) => "selected_filter_id_$index";
  static const String aspectRatioKey = "aspect_ratio";
  static const String initialDraggableSizeKey = "initial_draggable_size";
  static const String suspectIndexToDragKey = "suspect_index_to_drag";
  static const String imagesKey = "images";
  static const String croppingReadyKey = "cropping_ready";
  static const String rotationKey = "rotation";

  EditMediaViewModel initializeParameters({required EditImagePageParameters parameters}) {
    _aspectRatio = parameters.aspectRatio;
    _maxImageSelected = parameters.maxImageSelected;
    _parameters = parameters;
    _selectedImage = parameters.originSelectedImage;
    _originSelectedImg = parameters.originSelectedImg;
    _singleImageFile = parameters.originSelectedImage[0];
    _singleImageImg = parameters.originSelectedImg[0];
    _croppedSelectedImage = List.generate(
      parameters.originSelectedImage.length,
      (index) => parameters.originSelectedImage[index],
    );

    _croppedSelectedImg = List.generate(
      parameters.originSelectedImg.length,
      (index) => parameters.originSelectedImg[index],
    );

    _globalImagesKeys = setKeys(parameters.originSelectedImage);
    _selectedFiltersIndex = [...parameters.selectedFilersIndexes];
    _selectedRotation = [...parameters.selectedRotation];
    return this;
  }

  static List<GlobalKey<CustomCropperState>> setKeys(List<File> selectedImage) {
    return List.generate(
      selectedImage.length,
      (_) => GlobalKey<CustomCropperState>(),
    );
  }

  // Private fields
  late EditImagePageParameters _parameters;
  late double _aspectRatio;
  late List<File> _selectedImage;
  late File _singleImageFile;
  late img.Image _singleImageImg;
  late List<img.Image> _originSelectedImg;
  late List<File> _croppedSelectedImage;
  late List<img.Image> _croppedSelectedImg;
  late List<GlobalKey<CustomCropperState>> _globalImagesKeys;
  late List<int> _selectedRotation;
  late List<int> _selectedFiltersIndex;

  int? _maxImageSelected;

  bool _isCroppingReady = true;
  int? _suspectIndexToDrag;
  Size? _initialDraggableImageSize;

  // Getters
  GlobalKey<CustomCropperState> getImageKey(int index) => _globalImagesKeys[index];
  List<int> get selectedFiltersIndex => _selectedFiltersIndex;
  List<int> get selectedRotation => _selectedRotation;
  double get aspectRatio => _aspectRatio;
  bool get isCroppingReady => _isCroppingReady;
  bool get allowForAddMoreImages => allowForAddMoreImagesLimit > 0;
  img.Image get singleImageImg => _singleImageImg;
  File get singleImageFile => _singleImageFile;
  List<File> get selectedImage => _selectedImage;
  List<File> get croppedSelectedImage => _croppedSelectedImage;
  Size get initialDraggableImageSize => _initialDraggableImageSize ?? const Size(300, 300);
  int? get suspectIndexToDrag => _suspectIndexToDrag;

  int get allowForAddMoreImagesLimit {
    final limit = _parameters.maxImageSelected;
    if (limit == null) return 0;
    return limit - croppedSelectedImage.length;
  }

  // Setters
  set suspectIndexToDrag(int? value) {
    if (value == _suspectIndexToDrag) return;
    _suspectIndexToDrag = value;
    updateState([suspectIndexToDragKey]);
  }

  set maxImageSelected(int value) {
    final maxValue = _parameters.maxImageSelected;
    if (value == _maxImageSelected || maxValue == null) return;
    if (value > maxValue) {
      _maxImageSelected = maxValue;
    } else if (value >= 0) {
      _maxImageSelected = value;
    }
    updateState([]);
  }

  set initialDraggableImageSize(Size value) {
    if (_initialDraggableImageSize != null) return;
    _initialDraggableImageSize = value;
    updateState([initialDraggableSizeKey]);
  }

  // Methods for image management
  void updateReorderListView({required int oldIndex, required int newIndex}) {
    if (oldIndex < newIndex) newIndex -= 1;

    final croppedImageItem = _croppedSelectedImage.removeAt(oldIndex);
    _croppedSelectedImage.insert(newIndex, croppedImageItem);

    final croppedSelectedItem = _croppedSelectedImg.removeAt(oldIndex);
    _croppedSelectedImg.insert(newIndex, croppedSelectedItem);

    final originImageFile = _selectedImage.removeAt(oldIndex);
    _selectedImage.insert(newIndex, originImageFile);

    final filterItem = _selectedFiltersIndex.removeAt(oldIndex);
    _selectedFiltersIndex.insert(newIndex, filterItem);

    final rotateItem = _selectedRotation.removeAt(oldIndex);
    _selectedRotation.insert(newIndex, rotateItem);

    final keyItem = _globalImagesKeys.removeAt(oldIndex);
    _globalImagesKeys.insert(newIndex, keyItem);

    final originSelectedItem = _originSelectedImg.removeAt(oldIndex);
    _originSelectedImg.insert(newIndex, originSelectedItem);

    suspectIndexToDrag = null;

    updateState([imagesKey]);
  }

  void removeSpecificItem(int index) {
    _croppedSelectedImage.removeAt(index);
    _croppedSelectedImg.removeAt(index);
    _selectedImage.removeAt(index);
    _selectedFiltersIndex.removeAt(index);
    _selectedRotation.removeAt(index);
    _globalImagesKeys.removeAt(index);
    _originSelectedImg.removeAt(index);

    if (_maxImageSelected != null) {
      _maxImageSelected = _croppedSelectedImage.length;
    }

    if (_selectedImage.length == 1) {
      _singleImageImg = _croppedSelectedImg.first;
      _singleImageFile = _croppedSelectedImage.first;
    }

    updateState([imagesKey]);
  }

  // Filter-related methods
  List<double> getSelectedFilterMatrix({required int imageIndex}) =>
      ImageProcessing.getSelectedFilterMatrix(filterIndex: selectedFiltersIndex[imageIndex]);

  void changeAllSelectedImagesFilters(int value) {
    for (int i = 0; i < _selectedFiltersIndex.length; i++) {
      if (_selectedFiltersIndex[i] == value) continue;
      _selectedFiltersIndex[i] = value;
      updateState([selectedFilterId(i)]);
    }
  }

  void changeSingleImageFilter({required int filter, required int index}) {
    _selectedFiltersIndex[index] = filter;
    updateState([selectedFilterId(index)]);
  }

  // Image processing methods
  void setCroppingReady(bool value) {
    if (value == _isCroppingReady) return;
    _isCroppingReady = value;
    updateState([croppingReadyKey]);
  }

  /// todo: handle this and show popup list when it has more than 2 or even two to be standard
  void switchAspectRatio({double? value}) {
    final allowedAspectRatios = _parameters.allowedAspectRatios;
    if (allowedAspectRatios.length < 2) return;
    final double newValue =
        value ?? (aspectRatio == allowedAspectRatios[0] ? allowedAspectRatios[1] : allowedAspectRatios[0]);

    if (newValue == aspectRatio) return;
    _aspectRatio = newValue;
    _initialDraggableImageSize = null;

    updateState([aspectRatioKey]);
  }

  void nextTempRotation(ValueNotifier<int> angle, img.Image image, int index, {bool withClock = false}) {
    final newAngle = _getNextAngle(angle.value) * (withClock ? 1 : -1);
    _selectedRotation[index] = newAngle;
    angle.value = newAngle;
    updateState([rotationKey]);
  }

  static int _getNextAngle(int a) {
    final angle = a < 0 ? a * -1 : a;
    return angle + 90;
  }

  Future<img.Image?> _cropSingleImageWithKey({
    required GlobalKey<CustomCropperState> cropKey,
    required int imageIndex,
    required img.Image srcImage,
  }) async {
    final currentState = cropKey.currentState;
    if (currentState == null) return null;

    final area = currentState.area;
    final imageUi = currentState.image;
    if (area == null || imageUi == null) return null;

    final imageO = ImageProcessing._cropImage(image: srcImage, area: area, parameters: _parameters);

    final convertedImg =
        await Conversions.convertImgToFile(imageO, tempCacheSessionUUid: _parameters.tempCacheSessionUUid);

    _croppedSelectedImage[imageIndex] = convertedImg;
    _croppedSelectedImg[imageIndex] = imageO;

    updateState([imagesKey]);
    return imageO;
  }

  // Action methods
  Future<void> onTapDoneForSingleImage(
    BuildContext context, {
    required img.Image srcImage,
    required int imageIndex,
    required int filter,
    required int angle,
    required double aspectRatio,
    required bool isOnlySelectedImage,
    required GlobalKey<CustomCropperState> cropKey,
  }) async {
    if (!isCroppingReady) return;
    final instance = GeneralLoadingScreen.getInstance();

    try {
      instance.showAlertDialog(
        context,
        // backgroundColor: ThemeEnum.greyColor,
        text: StringsManager.processing,
        withLoadingIndicator: false,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      img.Image? imageParams = await _cropSingleImageWithKey(
        cropKey: cropKey,
        imageIndex: imageIndex,
        srcImage: srcImage,
      );

      if (imageParams == null) {
        instance.hide();
        if (context.mounted) {
          context.pop();

          /// todo:
          // context.toast(StringsManager.invalidImage, type: invalidToastType);
        }
        return;
      }

      changeSingleImageFilter(filter: filter, index: imageIndex);
      switchAspectRatio(value: aspectRatio);

      updateState([selectedFilterId(imageIndex)]);

      if (isOnlySelectedImage) {
        imageParams = ImageProcessing._applyFilter(
          image: imageParams,
          filter: getSelectedFilterMatrix(imageIndex: imageIndex),
        );
      }

      if (angle != 0) {
        imageParams = ImageProcessing.applyImageRotation(angle, imageParams, false);
      }

      File? imageFile = await Conversions.convertImgToFile(imageParams,
          tempCacheSessionUUid: _parameters.tempCacheSessionUUid);

      if (context.mounted) {
        _returnedValues(context, [imageFile]);
      }
    } catch (e) {
      if (context.mounted) {
        /// todo:
        // context.toast(StringsManager.somethingWentWrongWithImage, type: invalidToastType);
      }
      debugPrint("image error: =======>>>>>>> $e");
      instance.hide();
    }
    instance.hide();
  }

  Future<void> onTapNext(BuildContext context) async {
    if (!isCroppingReady) return;
    final instance = GeneralLoadingScreen.getInstance();

    try {
      instance.showAlertDialog(
        context,
        // backgroundColor: ThemeEnum.greyColor,
        text: StringsManager.processing,
        withLoadingIndicator: false,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final getAreas = _getImagesArea;
      final List<File> imagesFiles = await ImageProcessing._processAllImages(
        _ProcessImageParamsList(
          croppedImg: _croppedSelectedImg,
          croppedImage: _croppedSelectedImage,
          originImage: _selectedImage,
          originImg: _originSelectedImg,
          cropKey: getAreas,
          filterMatrix: _selectedFiltersIndex,
          rotationAngle: selectedRotation,
          parameters: _parameters,
        ),
      );

      if (context.mounted) {
        _returnProcessedImages(context, imagesFiles);
      }
      instance.hide();
    } catch (e) {
      if (context.mounted) {
        _handleProcessingError(context, e);
      }
      debugPrint("images tapOnNext error: =======>>>>>>> $e");
      instance.hide();
    }
    instance.hide();
  }

  List<Rect> get _getImagesArea {
    final List<Rect> list = [];
    for (int i = 0; i < _globalImagesKeys.length; i++) {
      final area = _globalImagesKeys[i].currentState?.area;
      if (area == null) {
        throw "invalid image";
      }
      list.add(area);
    }
    return list;
  }

  _returnProcessedImages(BuildContext context, List<File> imagesFiles) {
    final result = EditImagePageBaseParameters(
      editedImagesFiles: imagesFiles,
      originalImagesFiles: selectedImage,
      selectedFilersIndexes: selectedFiltersIndex,
      aspectRatio: aspectRatio,
      selectedRotation: selectedRotation,
      tempCacheSessionUUid: _parameters.tempCacheSessionUUid,
    );

    if (_parameters.croppedSelectedImage.length != 1 && imagesFiles.length == 1) {
      context.pop(result: result);
    } else {
      _parameters.onImageEditedFinish(context, result);
    }
  }

  void _handleProcessingError(BuildContext context, dynamic e) {
    if (context.mounted) {
      /// TODO:
      // context.toast(StringsManager.invalidImage, type: invalidToastType);
      debugPrint(e.toString());
    }
  }

  void _returnedValues(BuildContext context, List<File> imagesFiles) {
    final instance = GeneralLoadingScreen.getInstance();
    instance.hide();

    final result = EditImagePageBaseParameters(
      editedImagesFiles: imagesFiles,
      originalImagesFiles: selectedImage,
      selectedFilersIndexes: selectedFiltersIndex,
      aspectRatio: aspectRatio,
      selectedRotation: selectedRotation,
      tempCacheSessionUUid: _parameters.tempCacheSessionUUid,
    );

    if (_parameters.croppedSelectedImage.length != 1 && imagesFiles.length == 1) {
      return context.pop(result: result);
    }

    _parameters.onImageEditedFinish(context, result);
  }

  // Image addition methods
  Future<void> addMoreImages(BuildContext context) async {
    /// TODO: add this
    // try {
    //   context.pushTo(
    //     Routes.customImagePicker,
    //     arguments: CustomImagePickerParameters(
    //       saveToGallery: true,
    //       tempCacheSessionUUid: _parameters.tempCacheSessionUUid,
    //       maxPhotos: allowForAddMoreImagesLimit,
    //       onComplete: (_, files, images) async {
    //         if (files.isEmpty) return;
    //         context.pop();
    //
    //         _addNewSelectedParameters(
    //           originSelectedImg: images,
    //           originSelectedImage: files,
    //         );
    //       },
    //     ),
    //   );
    // } catch (error) {
    //   // Handle error if needed
    // }
  }

  /// TODO: belong to the above
  // void _addNewSelectedParameters({
  //   required List<File> originSelectedImage,
  //   required List<img.Image> originSelectedImg,
  // }) {
  //   for (int i = 0; i < originSelectedImage.length; i++) {
  //     final image = originSelectedImage[i];
  //     final img = originSelectedImg[i];
  //
  //     _selectedImage.add(image);
  //     _croppedSelectedImage.add(image);
  //     _croppedSelectedImg.add(img);
  //     _originSelectedImg.add(img);
  //
  //     _globalImagesKeys.add(GlobalKey<CustomCropperState>());
  //     _selectedFiltersIndex.add(0);
  //     _selectedRotation.add(0);
  //   }
  //
  //   _maxImageSelected = _croppedSelectedImage.length;
  //   updateState([imagesKey]);
  // }

  /// TODO:
  // Future<bool?> confirmDiscardAlert(BuildContext context) async {
  //   return CustomAlertDialog(context).openDialog(
  //     DialogParameters(
  //       title: StringsManager.discardConfirmation,
  //       content: StringsManager.discardConfirmationImageEditText,
  //       onTapAction: null,
  //       actionText: StringsManager.exist,
  //       onTapCancel: null,
  //     ),
  //   );
  // }
}

// Parameters for the isolate computation
class _ProcessImageParamsList {
  final List<img.Image> croppedImg;
  final List<File> croppedImage;
  final List<File> originImage;
  final List<img.Image> originImg;
  final List<Rect> cropKey;
  final List<int> filterMatrix;
  final List<int> rotationAngle;
  final EditImagePageParameters parameters;
  _ProcessImageParamsList({
    required this.croppedImg,
    required this.croppedImage,
    required this.originImage,
    required this.originImg,
    required this.cropKey,
    required this.filterMatrix,
    required this.rotationAngle,
    required this.parameters,
  });
}

class ImageProcessing {
  static Future<List<File>> _processAllImages(_ProcessImageParamsList paramsList) async {
    final List<Future<File>> list = [];
    final length = paramsList.croppedImage.length;

    for (int i = 0; i < length; i++) {
      list.add(_processImageInIsolate(i, paramsList));
    }

    return await Future.wait(list);
  }

  static List<double> getSelectedFilterMatrix({required int filterIndex}) => Filters.list[filterIndex].matrix;

  static Future<File> _processImageInIsolate(int i, _ProcessImageParamsList params) async {
    final croppedImage = params.croppedImage[i];
    final originImage = params.originImage[i];
    final cropKey = params.cropKey[i];
    final filter = getSelectedFilterMatrix(filterIndex: params.filterMatrix[i]);
    final rotation = params.rotationAngle[i];

    final croppedImg = croppedImage.path != originImage.path
        ? _cropImage(image: params.croppedImg[i], area: cropKey, parameters: params.parameters)
        : _cropImage(image: params.originImg[i], area: cropKey, parameters: params.parameters);

    final imageWithFilter = _applyFilter(image: croppedImg, filter: filter);

    final rotate = rotateImage(imageWithFilter, rotation);

    final file =
        Conversions.convertImgToFile(rotate, tempCacheSessionUUid: params.parameters.tempCacheSessionUUid);

    return file;
  }

  static img.Image _cropImage({
    required img.Image image,
    required Rect area,
    required EditImagePageParameters parameters,
  }) {
    return _cropAndResize(
      _CropImagePar(
          srcImage: image,
          left: area.left,
          top: area.top,
          right: area.right,
          bottom: area.bottom,
          parameters: parameters),
    );
  }

  static img.Image _cropAndResize(_CropImagePar par) {
    // Calculate crop area
    final int cropLeft = (par.left * par.srcImage.width).toInt();
    final int cropTop = (par.top * par.srcImage.height).toInt();
    final int cropRight = (par.right * par.srcImage.width).toInt();
    final int cropBottom = (par.bottom * par.srcImage.height).toInt();
    final int cropWidth = (cropRight - cropLeft);
    final int cropHeight = (cropBottom - cropTop);

    // Crop the image
    final croppedImage = img.copyCrop(
      par.srcImage,
      x: cropLeft,
      y: cropTop,
      width: (cropRight - cropLeft),
      height: (cropBottom - cropTop),
    );
    //
    // Resize the cropped image
    final img.Image resizedImage = img.copyResize(
      croppedImage,
      width: par.parameters.resizeWidth?.toInt() ?? cropWidth,
      height: par.parameters.resizeWidth?.toInt() ?? cropHeight,
    );

    return resizedImage;
  }

  static img.Image _applyFilter({required img.Image image, required List<double> filter}) {
    ApplyFilterParams params = ApplyFilterParams(img: image, colorMatrix: filter);

    img.Image processedImage;

    if (params.colorMatrix.isNotEmpty) {
      processedImage = FilterManager.applyFilter(params);
    } else {
      processedImage = image;
    }

    return processedImage;
  }

  static img.Image rotateImage(img.Image image, int angle) {
    img.Image rotatedImage = img.copyRotate(image, angle: angle);

    return rotatedImage;
  }

  static void switchTempAspectRatio(ValueNotifier<double> aspectRatio) {
    /// TODO: handle this aspect ratio
    // final double newValue = aspectRatio.value == fullAspectRatio ? subAspectRatio : fullAspectRatio;
    //
    // if (newValue == aspectRatio.value) return;
    // aspectRatio.value = newValue;
  }

  static img.Image applyImageRotation(int angle, img.Image image, bool withClock) {
    if (angle == 0) return image;

    return rotateImage(image, angle);
  }

  static Future<File?> flipHorizontalAndReplaceOriginal(File imageFile) async {
    return await compute(_flipHorizontalAndReplaceOriginal, imageFile);
  }

  static Future<File?> _flipHorizontalAndReplaceOriginal(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;
    final flippedImage = img.flipHorizontal(originalImage);

    return await imageFile.writeAsBytes(img.encodePng(flippedImage));
  }
}
