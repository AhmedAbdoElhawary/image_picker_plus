import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

void main() {
  /// width / height of the crop in pixels for a 2:1 image.
  double pixelAspect(Rect rect) => rect.width * 2 / rect.height;

  test("the ratio sets the rect aspect, centered", () {
    final crop = CropController(imageAspect: 2, ratio: CropRatio.square);
    expect(pixelAspect(crop.value), closeTo(1, 1e-9));
    expect(crop.value.height, 1);
    expect(crop.value.center.dx, closeTo(0.5, 1e-9));
    expect(crop.edited, isTrue);

    crop.ratio = CropRatio.landscape;
    expect(pixelAspect(crop.value), closeTo(16 / 9, 1e-9));
  });

  test("original uses the image ratio and is not an edit", () {
    final crop = CropController(imageAspect: 2, ratio: CropRatio.original);
    expect(crop.value, const Rect.fromLTWH(0, 0, 1, 1));
    expect(crop.edited, isFalse);
  });

  test("pan stays inside the image", () {
    final crop = CropController(imageAspect: 2, ratio: CropRatio.square);
    crop.pan(const Offset(5, 5));
    expect(crop.value.right, 1);
    expect(crop.value.bottom, 1);
    crop.pan(const Offset(-5, -5));
    expect(crop.value.left, 0);
    expect(crop.value.top, 0);
  });

  test("zoom keeps the aspect, stays inside, and has limits", () {
    final crop = CropController(imageAspect: 1, ratio: CropRatio.portrait);
    crop.zoomTo(2, focal: const Offset(0.9, 0.9));
    expect(crop.zoom, closeTo(2, 1e-9));
    expect(crop.value.width / crop.value.height, closeTo(0.8, 1e-9));
    expect(crop.value.right, lessThanOrEqualTo(1));
    expect(crop.value.bottom, lessThanOrEqualTo(1));

    crop.zoomTo(100);
    expect(crop.zoom, closeTo(1 / CropController.minScale, 1e-9));
    crop.zoomTo(0.1);
    expect(crop.zoom, closeTo(1, 1e-9));
  });

  test("setting the same ratio keeps the rect", () {
    final crop = CropController(imageAspect: 2, ratio: CropRatio.square);
    crop.pan(const Offset(0.1, 0));
    final rect = crop.value;
    crop.ratio = CropRatio.square;
    expect(crop.value, rect);
  });
}
