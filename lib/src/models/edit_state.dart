import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

/// what was done to one image, saved with [toMap] to open the picker with it again.
class EditState {
  /// normalized 0..1 of the image as shown, after [turns] and [flipped].
  final Rect cropRect;

  /// null when the crop was off.
  final CropRatio? ratio;

  /// 0 means no filter.
  final int filterIndex;

  /// what was added on top, in draw order. opaque to apps, it round trips through the map.
  final List<MarkupItem> markup;

  /// quarter turns counter clockwise, 0..3.
  final int turns;

  /// mirrored left to right, before the [turns].
  final bool flipped;

  /// the sliders, neutral when they were off or untouched.
  final Adjustments adjustments;

  /// no edit by default.
  const EditState({
    this.cropRect = full,
    this.ratio,
    this.filterIndex = 0,
    this.markup = const [],
    this.turns = 0,
    this.flipped = false,
    this.adjustments = Adjustments.neutral,
  });

  /// the whole image, no crop.
  static const Rect full = Rect.fromLTWH(0, 0, 1, 1);

  /// false when it's the image as it came in.
  bool get edited =>
      !_isFull(cropRect) ||
      filterIndex != 0 ||
      markup.isNotEmpty ||
      turns != 0 ||
      flipped ||
      !adjustments.isNeutral;

  /// a copy with the given parts changed.
  EditState copyWith({
    Rect? cropRect,
    CropRatio? ratio,
    int? filterIndex,
    List<MarkupItem>? markup,
    int? turns,
    bool? flipped,
    Adjustments? adjustments,
  }) => EditState(
    cropRect: cropRect ?? this.cropRect,
    ratio: ratio ?? this.ratio,
    filterIndex: filterIndex ?? this.filterIndex,
    markup: markup ?? this.markup,
    turns: turns ?? this.turns,
    flipped: flipped ?? this.flipped,
    adjustments: adjustments ?? this.adjustments,
  );

  /// json safe, [EditState.fromMap] reads it back.
  Map<String, Object?> toMap() {
    final ratio = this.ratio;
    return {
      "crop": [cropRect.left, cropRect.top, cropRect.width, cropRect.height],
      if (ratio != null) "ratio": ratio == CropRatio.original ? "original" : [ratio.width, ratio.height],
      "filter": filterIndex,
      if (markup.isNotEmpty) "markup": [for (final item in markup) item.toMap()],
      if (turns != 0) "turns": turns,
      if (flipped) "flip": true,
      if (!adjustments.isNeutral)
        "adjust": [adjustments.brightness, adjustments.contrast, adjustments.saturation, adjustments.warmth],
    };
  }

  /// a missing or broken key gets its default, so a map from an older version still loads.
  factory EditState.fromMap(Map<String, Object?> map) {
    final crop = map["crop"];
    final ratio = map["ratio"];
    final filter = map["filter"];
    final markup = map["markup"];
    final turns = map["turns"];
    final adjust = map["adjust"];
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
      turns: turns is int ? turns % 4 : 0,
      flipped: map["flip"] == true,
      adjustments: adjust is List && adjust.length == 4 && adjust.every((value) => value is num)
          ? Adjustments(
              brightness: (adjust[0] as num).toDouble().clamp(-1, 1),
              contrast: (adjust[1] as num).toDouble().clamp(-1, 1),
              saturation: (adjust[2] as num).toDouble().clamp(-1, 1),
              warmth: (adjust[3] as num).toDouble().clamp(-1, 1),
            )
          : Adjustments.neutral,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EditState &&
      other.cropRect == cropRect &&
      other.ratio == ratio &&
      other.filterIndex == filterIndex &&
      listEquals(other.markup, markup) &&
      other.turns == turns &&
      other.flipped == flipped &&
      other.adjustments == adjustments;

  @override
  int get hashCode =>
      Object.hash(cropRect, ratio, filterIndex, Object.hashAll(markup), turns, flipped, adjustments);

  // pan math leaves tiny float errors, they're not a real crop
  static bool _isFull(Rect rect) =>
      rect.left < 0.001 && rect.top < 0.001 && rect.right > 0.999 && rect.bottom > 0.999;
}
