import 'dart:ui';

import 'package:image_picker_plus/src/settings/crop_ratio.dart';

class EditState {
  /// normalized 0..1 of the image.
  final Rect cropRect;

  /// null when the crop was off.
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

  Map<String, Object?> toMap() {
    final ratio = this.ratio;
    return {
      "crop": [cropRect.left, cropRect.top, cropRect.width, cropRect.height],
      if (ratio != null) "ratio": ratio == CropRatio.original ? "original" : [ratio.width, ratio.height],
      "filter": filterIndex,
    };
  }

  /// a missing or broken key gets its default, so a map from an older version still loads.
  factory EditState.fromMap(Map<String, Object?> map) {
    final crop = map["crop"];
    final ratio = map["ratio"];
    final filter = map["filter"];
    return EditState(
      cropRect: crop is List && crop.length == 4 && crop.every((value) => value is num)
          ? Rect.fromLTWH(
              (crop[0] as num).toDouble(),
              (crop[1] as num).toDouble(),
              (crop[2] as num).toDouble(),
              (crop[3] as num).toDouble(),
            )
          : full,
      ratio: switch (ratio) {
        "original" => CropRatio.original,
        [final num width, final num height] when width > 0 && height > 0 => CropRatio(
          width.toDouble(),
          height.toDouble(),
        ),
        _ => null,
      },
      filterIndex: filter is int && filter >= 0 ? filter : 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EditState &&
      other.cropRect == cropRect &&
      other.ratio == ratio &&
      other.filterIndex == filterIndex;

  @override
  int get hashCode => Object.hash(cropRect, ratio, filterIndex);

  // pan math leaves tiny float errors, they're not a real crop
  static bool _isFull(Rect rect) =>
      rect.left < 0.001 && rect.top < 0.001 && rect.right > 0.999 && rect.bottom > 0.999;
}
