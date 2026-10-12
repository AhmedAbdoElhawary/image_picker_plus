import 'package:image_picker_plus/src/settings/camera_options.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/markup_options.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_cache.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';

/// where the picker opens.
enum PickerSource {
  /// the gallery only.
  gallery,

  /// the camera only.
  camera,

  /// the gallery with a camera tab.
  both,
}

/// what can be picked.
enum MediaType {
  /// photos only.
  image,

  /// videos only.
  video,

  /// photos and videos.
  all,
}

/// everything the picker can be set up with.
class PickerSettings {
  /// gallery by default.
  final PickerSource source;

  /// the camera page's extra controls.
  final CameraOptions camera;

  /// images only by default.
  final MediaType mediaType;

  /// 1 means single selection.
  final int maxSelection;

  /// empty means no crop.
  final List<CropRatio> cropRatios;

  /// the rotate left button under the crop.
  final bool rotate;

  /// the flip button under the crop.
  final bool flip;

  /// false hides the gallery preview, the crop is then only on the edit page at the image's own ratio.
  final bool showPreview;

  /// decodes the preview and edit images at the size they're shown, false decodes them at 1080 pixels.
  /// false uses more memory but stays sharper when zooming the crop.
  final bool resizePreview;

  /// images per row, null follows the screen width.
  final int? gridColumns;

  /// width / height of a grid cell, 0.5 is twice as tall as wide.
  final double gridCellAspectRatio;

  /// the looks on the filter strip after "Normal", empty hides the strip. [PickerFilter.all] for the shipped ones.
  final List<PickerFilter> filters;

  /// brightness, contrast, saturation and warmth sliders on the edit page.
  final bool adjustments;

  /// text, emojis and drawing, all off by default.
  final MarkupOptions markup;

  /// how edited images are saved, jpeg at 90 by default.
  final OutputOptions output;

  /// null uses the dark theme, or follows the app brightness when [alwaysDarkTheme] is false.
  final PickerTheme? theme;

  /// false follows the app brightness. a custom [theme] wins over it.
  final bool alwaysDarkTheme;

  /// english by default. [PickerTexts.of] follows the app's language.
  final PickerTexts texts;

  /// off by default.
  final PickerCache cache;

  /// false pushes on the nearest navigator, which keeps a tab bar or a nested
  /// shell visible over the picker.
  final bool useRootNavigator;

  /// a single image from the gallery, with the crop.
  const PickerSettings({
    this.useRootNavigator = false,
    this.source = PickerSource.gallery,
    this.camera = const CameraOptions(),
    this.mediaType = MediaType.image,
    this.maxSelection = 1,
    this.cropRatios = CropRatio.all,
    this.rotate = true,
    this.flip = true,
    this.showPreview = true,
    this.resizePreview = true,
    this.gridColumns,
    this.gridCellAspectRatio = 1,
    this.filters = const [],
    this.adjustments = false,
    this.markup = const MarkupOptions(),
    this.output = const OutputOptions(),
    this.theme,
    this.alwaysDarkTheme = true,
    this.texts = const PickerTexts(),
    this.cache = const PickerCache(),
  }) : assert(maxSelection >= 1),
       assert(gridColumns == null || gridColumns > 0),
       assert(gridCellAspectRatio > 0);

  /// true when the edit page has something to show.
  bool get editing => cropRatios.isNotEmpty || filters.isNotEmpty || adjustments || markup.enabled;

  /// true when more than one can be picked.
  bool get multi => maxSelection > 1;
}
