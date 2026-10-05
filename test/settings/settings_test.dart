import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/settings/camera_options.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/markup_options.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';
import 'package:image_picker_plus/src/settings/picker_cache.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

void main() {
  test("defaults", () {
    const settings = PickerSettings();
    expect(settings.source, PickerSource.gallery);
    expect(settings.mediaType, MediaType.image);
    expect(settings.maxSelection, 1);
    expect(settings.cropRatios, CropRatio.all);
    expect(settings.resizePreview, isTrue);
    expect(settings.filters, isFalse);
    expect(settings.output.quality, 90);
    expect(settings.output.maxWidth, isNull);
    expect(settings.cache.enabled, isFalse);
    expect(settings.cache.maxBytes, 100 * 1024 * 1024);
    expect(settings.theme, isNull);
    expect(settings.alwaysDarkTheme, isTrue);
    expect(settings.editing, isTrue);
    expect(settings.multi, isFalse);
  });

  test("editing and multi", () {
    expect(const PickerSettings(filters: true).editing, isTrue);
    expect(const PickerSettings(cropRatios: [CropRatio.square]).editing, isTrue);
    expect(const PickerSettings(cropRatios: []).editing, isFalse);
    expect(const PickerSettings(maxSelection: 3).multi, isTrue);
  });

  test("asserts", () {
    expect(() => PickerSettings(maxSelection: 0), throwsAssertionError);
    expect(() => OutputOptions(quality: 0), throwsAssertionError);
    expect(() => OutputOptions(quality: 101), throwsAssertionError);
    expect(() => OutputOptions(maxWidth: 0), throwsAssertionError);
    expect(() => OutputOptions(maxHeight: -1), throwsAssertionError);
    expect(() => PickerCache(maxBytes: 0), throwsAssertionError);
    expect(() => CropRatio(0, 1), throwsAssertionError);
  });

  test("crop ratios", () {
    expect(CropRatio.original.ratio, isNull);
    expect(CropRatio.square.ratio, 1);
    expect(CropRatio.portrait.ratio, 0.8);
    expect(CropRatio.landscape.ratio, 16 / 9);
    expect(CropRatio.landscape.toString(), "16:9");
    expect(CropRatio.original.toString(), "original");
    expect(const CropRatio(1, 1), CropRatio.square);
    expect(OutputOptions.safeMaxSide, 4096);
  });

  test("max bytes and limits", () {
    expect(const OutputOptions().hasLimits, isFalse);
    expect(const OutputOptions(maxWidth: 10).hasLimits, isTrue);
    expect(const OutputOptions(maxBytes: 1000).hasLimits, isTrue);
    expect(() => OutputOptions(maxBytes: 0), throwsAssertionError);
    expect(OutputOptions.qualityFloor, 50);
  });

  test("camera options are all on by default, grid off at start", () {
    const camera = CameraOptions();
    expect(
      (camera.zoomButtons, camera.timer, camera.grid, camera.gridOn, camera.overlay),
      (true, true, true, false, null),
    );
    expect(const PickerSettings().camera.zoomButtons, isTrue);
  });

  test("markup is off by default, any tool turns editing on", () {
    const off = MarkupOptions();
    expect((off.text, off.drawing, off.enabled), (false, false, false));
    expect(off.fonts, isEmpty);
    expect(off.colors, MarkupOptions.defaultColors);
    expect(const PickerSettings(cropRatios: [], markup: MarkupOptions(text: true)).editing, isTrue);
    expect(const PickerSettings(cropRatios: [], markup: MarkupOptions()).editing, isFalse);
  });
}
