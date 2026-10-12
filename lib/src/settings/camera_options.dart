import 'package:flutter/widgets.dart';

/// builds what's drawn over the camera preview, like a document frame.
typedef CameraOverlayBuilder = Widget Function(BuildContext context, Size previewSize);

/// the camera page's extra controls.
class CameraOptions {
  /// the 0.5x, 1x, 2x and max buttons. pinch zoom works either way.
  final bool zoomButtons;

  /// the 3 and 10 second timer button.
  final bool timer;

  /// the button that turns the rule of thirds grid on and off.
  final bool grid;

  /// the grid shows when the camera opens.
  final bool gridOn;

  /// drawn over the preview, under the controls, never in the photo or video.
  /// it doesn't get taps, so focus and zoom work through it.
  final CameraOverlayBuilder? overlay;

  /// every control on, the grid off at start.
  const CameraOptions({
    this.zoomButtons = true,
    this.timer = true,
    this.grid = true,
    this.gridOn = false,
    this.overlay,
  });
}
