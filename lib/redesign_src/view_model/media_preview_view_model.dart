import 'package:flutter/material.dart';
import 'package:image_picker_plus/redesign_src/custom_state_management/base_custom_state.dart';

class MediaPreviewViewModel extends BaseCustomState {
  static final MediaPreviewViewModel _instance = MediaPreviewViewModel._internal();
  factory MediaPreviewViewModel() => _instance;
  MediaPreviewViewModel._internal();

  /// need to be width as it is square
  static double getPreviewHeight(BuildContext context) => MediaQuery.sizeOf(context).width;

  static final String currentTopHidePreviewPositionId = 'currentTopHidePreviewPosition';

  /// -----------------------------------------------------------------------------------------
  double _currentTopHidePreviewPosition = 0;
  bool _makeAnimatedPosition = false;

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

  void handlePreviewPosition(BuildContext context, ScrollNotification notification) {
    final previewHeight = getPreviewHeight(context);
    final currentPixel = notification.metrics.pixels;

    /// cancel the animation
    if (currentPixel < previewHeight) _setMakeAnimatedPosition = false;

    final value = currentPixel < previewHeight ? currentPixel : previewHeight;
    _setCurrentTopHidePreviewPosition = value * -1;
  }

  void showPreviewFully(BuildContext context) {
    _setMakeAnimatedPosition = true;
    _setCurrentTopHidePreviewPosition = 0;
  }
}
