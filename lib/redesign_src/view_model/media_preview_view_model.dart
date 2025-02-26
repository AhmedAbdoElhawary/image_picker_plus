import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/core/custom_screen_adapter/screen_size_extension.dart'
    show ScreenSizeHelper;
import 'package:image_picker_plus/redesign_src/core/custom_state_management/base_custom_state.dart'
    show BaseCustomState;
import 'package:photo_manager/photo_manager.dart';

class MediaPreviewViewModel extends BaseCustomState {
  static final MediaPreviewViewModel _instance = MediaPreviewViewModel._internal();
  factory MediaPreviewViewModel() => _instance;
  MediaPreviewViewModel._internal() {
    fetchNewMedia();
    scrollController.addListener(_scrollMediaListener);
  }
  static int countPerPage = 60;

  /// need to be width as it is square
  static double getPreviewHeight() => ScreenSizeHelper().getScreenSize.width;

  static final String currentTopHidePreviewPositionId = 'currentTopHidePreviewPosition';
  static final String loadedMediaId = 'loadedMedia';
  static final String selectedMediaId = 'selectedMedia';
  static final String allowMultiSelectionId = 'allowMultiSelection';
  static String selectedBlurSingleMediaId(String path) => 'selectedBlurSingleMedia:$path';
  static String selectedIndexSingleMediaId(String path) => 'selectedIndexSingleMedia:$path';

  /// -----------------------------------------------------------------------------------------
  final ScrollController scrollController = ScrollController();
  double _currentTopHidePreviewPosition = 0;
  bool _makeAnimatedPosition = false;
  int _nextLoadedPage = 0;
  bool _hasPermissionAccess = false;
  final List<File?> _loadedMedia = <File?>[];
  final List<File> _selectedMultiMedia = [];
  File? _currentSelectedMedia;
  bool _allowMultiSelection = false;

  List<File?> get loadedMedia => _loadedMedia;
  List<File>? get selectedMultiMedia => _selectedMultiMedia;
  File? get currentSelectedMedia => _currentSelectedMedia;
  bool get allowMultiSelection => _allowMultiSelection;

  set allowMultiSelection(bool value) {
    if (value == allowMultiSelection) return;
    _allowMultiSelection = value;
    if (!value) _selectedMultiMedia.clear();

    updateState([allowMultiSelectionId]);
  }

  set addSingleSelectedMedia(File? value) {
    final isAdded = _selectedMultiMedia.contains(value) == true;
    if (isAdded && value?.path == currentSelectedMedia?.path) {
      _removeSingleMedia = value;
      return;
    }

    _updateCurrentSelectedMedia = value;

    if (isAdded || value == null) return;

    _selectedMultiMedia.add(value);

    updateState([selectedIndexSingleMediaId(value.path)]);
  }

  set _removeSingleMedia(File? value) {
    if (value == null) return;
    final removeIndex = _selectedMultiMedia.indexOf(value);
    _selectedMultiMedia.remove(value);
    if (removeIndex - 1 >= 0) _updateCurrentSelectedMedia = _selectedMultiMedia[removeIndex - 1];

    /// to update new count for all selection media
    _updateAllSelectedMedia();

    /// to remove count from removed selection
    updateState([selectedIndexSingleMediaId(value.path)]);
  }

  void _updateAllSelectedMedia() {
    for (final element in _selectedMultiMedia) {
      updateState([selectedIndexSingleMediaId(element.path)]);
    }
  }

  int getNumberOfSelectedMedia(File? file) {
    if (file == null) return 0;
    return (_selectedMultiMedia.indexOf(file)) + 1;
  }

  set _updateCurrentSelectedMedia(File? value) {
    if (_currentSelectedMedia == value || value == null) return;
    final previousSelectedPath = _currentSelectedMedia?.path ?? "";
    _currentSelectedMedia = value;

    updateState([
      selectedMediaId,

      /// to update only selected small grid media
      selectedBlurSingleMediaId(value.path),

      /// to update and cancel only none selected small grid media
      selectedBlurSingleMediaId(previousSelectedPath)
    ]);
    appearPreview();
  }

  set _addAllMedia(List<File?> value) {
    if (value == _loadedMedia) return;
    _loadedMedia.addAll(value);
    updateState([loadedMediaId]);
  }

  bool get hasPermissionAccess => _hasPermissionAccess;
  set _setFullPermissionAccess(bool value) {
    if (value == _hasPermissionAccess) return;
    _hasPermissionAccess = value;
  }

  int get nextLoadedPage => _nextLoadedPage;

  set _setNextLoadedPage(int value) {
    if (value == _nextLoadedPage) return;
    _nextLoadedPage = value;
  }

  double get currentTopHidePreviewPosition => _currentTopHidePreviewPosition;

  set _setCurrentTopHidePreviewPosition(double value) {
    if (value == _currentTopHidePreviewPosition) return;
    _currentTopHidePreviewPosition = value;
    updateState([currentTopHidePreviewPositionId]);
  }

  bool get makeAnimatedPosition => _makeAnimatedPosition;

  set _setMakeAnimatedPosition(bool value) {
    if (value == _makeAnimatedPosition) return;
    _makeAnimatedPosition = value;
  }

  void handlePreviewPosition(double currentPixel, {bool showOriginPosition = false}) {
    final previewHeight = getPreviewHeight();

    /// cancel the animation
    if (currentPixel < previewHeight) _setMakeAnimatedPosition = false;

    final value = currentPixel < previewHeight ? currentPixel : previewHeight;
    _setCurrentTopHidePreviewPosition = showOriginPosition ? value : value * -1;
  }

  void disappearPreview() {
    final previewHeight = getPreviewHeight() * -1;

    _setMakeAnimatedPosition = true;
    _setCurrentTopHidePreviewPosition = previewHeight;
  }

  void appearPreview() {
    _setMakeAnimatedPosition = true;
    _setCurrentTopHidePreviewPosition = 0;
  }

  int _currentPage = 0;
  Future<void> _scrollMediaListener() async {
    final max = scrollController.position.maxScrollExtent;
    final currentPixel = scrollController.position.pixels / max;

    if (currentPixel > 0.2 && _nextLoadedPage != _currentPage) await fetchNewMedia();
  }

  Future<void> fetchNewMedia() async {
    if (!hasPermissionAccess) {
      final result = await _requestPermission();
      if (!result) return;
    }

    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;

    List<AssetEntity> media = await albums[0].getAssetListPaged(page: nextLoadedPage, size: countPerPage);

    /// in case, user go to permission and cancel our permission
    if (media.isEmpty) {
      await _requestPermission();
    } else {
      _currentPage = _nextLoadedPage;
      _setNextLoadedPage = _nextLoadedPage + 1;
    }

    final value = await Future.wait(media.map((e) => e.file).toList());
    value.removeWhere((element) => element == null);
    _addAllMedia = value;

    if (nextLoadedPage == 1) addSingleSelectedMedia = value.firstOrNull;
  }

  Future<bool> _requestPermission() async {
    PermissionState result = await PhotoManager.requestPermissionExtend();
    if (!result.hasAccess) {
      final result = await PhotoManager.requestPermissionExtend();
      _setFullPermissionAccess = result.hasAccess;
    } else {
      _setFullPermissionAccess = true;
    }
    return hasPermissionAccess;
  }
}
