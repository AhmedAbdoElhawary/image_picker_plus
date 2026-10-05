import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/filters.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';

void main() {
  test("maxReachedFor puts the number in", () {
    expect(const PickerTexts().maxReachedFor(5), "You can select up to 5 items");
    expect(const PickerTexts(maxReached: "max {max}").maxReachedFor(2), "max 2");
  });

  test("maxKeptFor puts the number in", () {
    expect(const PickerTexts().maxKeptFor(5), "Only the first 5 were kept");
    expect(const PickerTexts(maxKept: "kept {max}").maxKeptFor(3), "kept 3");
    expect(const PickerTexts().filesSkipped, "Some files couldn't be opened");
  });

  test("one name per filter", () {
    expect(const PickerTexts().filterNames.length, filters.length);
    for (final matrix in filters) {
      expect(matrix.length, 20);
    }
  });

  test("camera texts put the number in", () {
    expect(const PickerTexts().timerSecondsFor(3), "Timer 3 seconds");
    expect(const PickerTexts().zoomLevelFor("2"), "Zoom 2x");
    expect(const PickerTexts(timerSeconds: "{seconds}s").timerSecondsFor(10), "10s");
    expect(
      (const PickerTexts().timer, const PickerTexts().timerOff, const PickerTexts().grid),
      ("Timer", "Timer off", "Grid"),
    );
  });

  test("markup texts", () {
    const texts = PickerTexts();
    expect(
      [texts.text, texts.draw, texts.emojis, texts.undo, texts.redo, texts.eraser],
      ["Text", "Draw", "Emojis", "Undo", "Redo", "Eraser"],
    );
    expect(
      [texts.delete, texts.font, texts.textBackground, texts.color, texts.size, texts.doneEditing],
      ["Drag here to delete", "Font", "Background", "Color", "Size", "Done"],
    );
  });
}
