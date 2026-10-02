import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_cache.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';

enum PickerSource { gallery, camera, both }

enum MediaType { image, video, all }

class PickerSettings {
  final PickerSource source;
  final MediaType mediaType;

  /// 1 means single selection.
  final int maxSelection;

  /// empty means no crop.
  final List<CropRatio> cropRatios;

  /// false hides the gallery preview, the crop is then only on the edit page at the image's own ratio.
  final bool showPreview;

  /// decodes the preview and edit images at the size they're shown, false decodes them at 1080 pixels.
  /// false uses more memory but stays sharper when zooming the crop.
  final bool resizePreview;

  /// images per row, null follows the screen width.
  final int? gridColumns;

  /// width / height of a grid cell, 0.5 is twice as tall as wide.
  final double gridCellAspectRatio;
  final bool filters;
  final OutputOptions output;

  /// null uses the dark theme, or follows the app brightness when [alwaysDarkTheme] is false.
  final PickerTheme? theme;

  /// false follows the app brightness. a custom [theme] wins over it.
  final bool alwaysDarkTheme;
  final PickerTexts texts;
  final PickerCache cache;

  const PickerSettings({
    this.source = PickerSource.gallery,
    this.mediaType = MediaType.image,
    this.maxSelection = 1,
    this.cropRatios = const [],
    this.showPreview = true,
    this.resizePreview = true,
    this.gridColumns,
    this.gridCellAspectRatio = 1,
    this.filters = false,
    this.output = const OutputOptions(),
    this.theme,
    this.alwaysDarkTheme = true,
    this.texts = const PickerTexts(),
    this.cache = const PickerCache(),
  }) : assert(maxSelection >= 1),
       assert(gridColumns == null || gridColumns > 0),
       assert(gridCellAspectRatio > 0);

  bool get editing => cropRatios.isNotEmpty || filters;

  bool get multi => maxSelection > 1;
}
