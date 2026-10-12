import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';

void main() {
  test("columns by width", () {
    expect(PickerLayout.forSize(const Size(400, 800)).columns, 4);
    expect(PickerLayout.forSize(const Size(800, 1000)).columns, 6);
    expect(PickerLayout.forSize(const Size(1200, 900)).columns, 8);
  });

  test("popups on tablets and open foldables, sheets on phones either way up", () {
    expect(PickerLayout.forSize(const Size(400, 800)).popups, isFalse);
    expect(PickerLayout.forSize(const Size(800, 400)).popups, isFalse);
    expect(PickerLayout.forSize(const Size(841, 701)).popups, isTrue);
    expect(PickerLayout.forSize(const Size(800, 1200)).popups, isTrue);
  });

  test("desktop popups follow the window width", () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(PickerLayout.forSize(const Size(800, 500)).popups, isTrue);
    expect(PickerLayout.forSize(const Size(500, 800)).popups, isFalse);
  });

  test("preview beside", () {
    expect(PickerLayout.forSize(const Size(400, 800)).previewBeside, isFalse);
    expect(PickerLayout.forSize(const Size(800, 1000)).previewBeside, isFalse);
    expect(PickerLayout.forSize(const Size(800, 400)).previewBeside, isTrue);
    expect(PickerLayout.forSize(const Size(1200, 1400)).previewBeside, isTrue);
  });
}
