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
  final bool filters;
  final OutputOptions output;

  /// null follows the app brightness.
  final PickerTheme? theme;
  final PickerTexts texts;
  final PickerCache cache;

  const PickerSettings({
    this.source = PickerSource.gallery,
    this.mediaType = MediaType.image,
    this.maxSelection = 1,
    this.cropRatios = const [],
    this.filters = false,
    this.output = const OutputOptions(),
    this.theme,
    this.texts = const PickerTexts(),
    this.cache = const PickerCache(),
  }) : assert(maxSelection >= 1);

  bool get editing => cropRatios.isNotEmpty || filters;

  bool get multi => maxSelection > 1;
}
