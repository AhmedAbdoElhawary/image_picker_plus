import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';

class EditState {
  /// normalized 0..1 of the image.
  final Rect cropRect;
  final CropRatio? ratio;

  /// 0 means no filter.
  final int filterIndex;

  const EditState({this.cropRect = full, this.ratio, this.filterIndex = 0});

  static const Rect full = Rect.fromLTWH(0, 0, 1, 1);

  bool get edited => !_isFull(cropRect) || filterIndex != 0;

  EditState copyWith({Rect? cropRect, CropRatio? ratio, int? filterIndex}) => EditState(
    cropRect: cropRect ?? this.cropRect,
    ratio: ratio ?? this.ratio,
    filterIndex: filterIndex ?? this.filterIndex,
  );

  // pan math leaves tiny float errors, they're not a real crop
  static bool _isFull(Rect rect) =>
      rect.left < 0.001 && rect.top < 0.001 && rect.right > 0.999 && rect.bottom > 0.999;
}

abstract class ImageService {
  /// [cacheKey] names the same edit of the same image, used when caching is on.
  Future<PickedItem> export(
    XFile source,
    EditState state,
    List<double> colorMatrix,
    OutputOptions output, {
    String? cacheKey,
  });
}
