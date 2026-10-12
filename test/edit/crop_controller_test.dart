import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
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

  group("rotate and flip", () {
    EditState stateOf(CropController crop) =>
        EditState(cropRect: crop.value, turns: crop.turns, flipped: crop.flipped);

    test("four turns and two flips of a fresh crop are back where they started", () {
      for (final ratio in [CropRatio.square, CropRatio.portrait, CropRatio.original]) {
        final crop = CropController(imageAspect: 1.5, ratio: ratio);
        final start = crop.value;
        for (var i = 0; i < 4; i++) {
          crop.rotate();
        }
        crop
          ..flip()
          ..flip();
        expect((crop.turns, crop.flipped), (0, false));
        expect(crop.value.left, closeTo(start.left, 1e-9));
        expect(crop.value.width, closeTo(start.width, 1e-9));
        expect(stateOf(crop).edited, EditState(cropRect: start).edited);
      }
    });

    test("a turn swaps the shown aspect, a square crop turns with the image", () {
      final crop = CropController(imageAspect: 2, ratio: CropRatio.square)..pan(const Offset(-1, 0));
      expect(crop.value.left, 0);
      crop.rotate();
      expect(crop.imageAspect, 0.5);
      expect(crop.sourceAspect, 2);
      // the left half of a wide image is the bottom half once turned counter clockwise
      expect(crop.value.top, closeTo(0.5, 1e-9));
      expect(crop.value.width * crop.imageAspect / crop.value.height, closeTo(1, 1e-9));
    });

    test("a turn with another ratio gives its biggest centred crop", () {
      final crop = CropController(imageAspect: 1.5, ratio: CropRatio.portrait)..pan(const Offset(-1, 0));
      crop.rotate();
      expect(crop.value.center.dx, closeTo(0.5, 1e-9));
      expect(crop.value.center.dy, closeTo(0.5, 1e-9));
      expect(crop.value.width * crop.imageAspect / crop.value.height, closeTo(0.8, 1e-9));
    });

    test("a flip mirrors the crop and turns the other way", () {
      final crop = CropController(imageAspect: 2, ratio: CropRatio.square)..pan(const Offset(-1, 0));
      crop
        ..rotate()
        ..flip();
      expect((crop.turns, crop.flipped), (3, true));
      final mirrored = CropController(imageAspect: 2, ratio: CropRatio.square)
        ..pan(const Offset(-1, 0))
        ..flip();
      expect(mirrored.value.right, closeTo(1, 1e-9));
    });

    test("listeners and onOrient hear every move, with the aspect before it", () {
      final crop = CropController(imageAspect: 1, ratio: CropRatio.original);
      final moves = <(bool, double)>[];
      var heard = 0;
      crop
        ..addListener(() => heard++)
        ..onOrient = ((flip, aspect) => moves.add((flip, aspect)))
        ..rotate()
        ..flip();
      expect(heard, 2);
      expect(moves, [(false, 1.0), (true, 1.0)]);
    });

    test("restored turns are kept in range", () {
      expect(CropController(imageAspect: 1, ratio: CropRatio.square, turns: 6).turns, 2);
    });
  });
}
