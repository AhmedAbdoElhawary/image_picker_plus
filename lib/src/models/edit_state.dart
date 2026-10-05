import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

class EditState {
  /// normalized 0..1 of the image.
  final Rect cropRect;

  /// null when the crop was off.
  final CropRatio? ratio;

  /// 0 means no filter.
  final int filterIndex;

  /// what was added on top, in draw order. opaque to apps, it round trips through the map.
  final List<MarkupItem> markup;

  const EditState({this.cropRect = full, this.ratio, this.filterIndex = 0, this.markup = const []});

  static const Rect full = Rect.fromLTWH(0, 0, 1, 1);

  bool get edited => !_isFull(cropRect) || filterIndex != 0 || markup.isNotEmpty;

  EditState copyWith({Rect? cropRect, CropRatio? ratio, int? filterIndex, List<MarkupItem>? markup}) =>
      EditState(
        cropRect: cropRect ?? this.cropRect,
        ratio: ratio ?? this.ratio,
        filterIndex: filterIndex ?? this.filterIndex,
        markup: markup ?? this.markup,
      );

  Map<String, Object?> toMap() {
    final ratio = this.ratio;
    return {
      "crop": [cropRect.left, cropRect.top, cropRect.width, cropRect.height],
      if (ratio != null) "ratio": ratio == CropRatio.original ? "original" : [ratio.width, ratio.height],
      "filter": filterIndex,
      if (markup.isNotEmpty) "markup": [for (final item in markup) item.toMap()],
    };
  }

  /// a missing or broken key gets its default, so a map from an older version still loads.
  factory EditState.fromMap(Map<String, Object?> map) {
    final crop = map["crop"];
    final ratio = map["ratio"];
    final filter = map["filter"];
    final markup = map["markup"];
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
      markup: markup is List
          ? [
              for (final item in markup)
                if (item is Map) ?MarkupItem.fromMap(item.cast<String, Object?>()),
            ]
          : const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EditState &&
      other.cropRect == cropRect &&
      other.ratio == ratio &&
      other.filterIndex == filterIndex &&
      listEquals(other.markup, markup);

  @override
  int get hashCode => Object.hash(cropRect, ratio, filterIndex, Object.hashAll(markup));

  // pan math leaves tiny float errors, they're not a real crop
  static bool _isFull(Rect rect) =>
      rect.left < 0.001 && rect.top < 0.001 && rect.right > 0.999 && rect.bottom > 0.999;
}
