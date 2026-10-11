import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/settings/languages/arabic_texts.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
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

  test("one name per filter, Normal first", () {
    expect(const PickerTexts().filterNames.length, PickerFilter.all.length + 1);
    expect(const PickerTexts().filterNames.first, "Normal");
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

  test("rotate, filter and slider texts", () {
    const texts = PickerTexts();
    expect(
      [texts.rotate, texts.flip, texts.filters, texts.adjust, texts.reset],
      ["Rotate", "Flip", "Filters", "Adjust", "Reset"],
    );
    expect(
      [texts.brightness, texts.contrast, texts.saturation, texts.warmth],
      ["Brightness", "Contrast", "Saturation", "Warmth"],
    );
  });

  group("of", () {
    Future<PickerTexts> textsIn(WidgetTester tester, Locale? locale) async {
      late PickerTexts texts;
      final probe = Builder(
        builder: (context) {
          texts = PickerTexts.of(context);
          return const SizedBox();
        },
      );
      await tester.pumpWidget(
        locale == null
            ? probe
            : Localizations(
                locale: locale,
                delegates: const [DefaultWidgetsLocalizations.delegate],
                child: probe,
              ),
      );
      return texts;
    }

    testWidgets("matches the language code, english for the rest", (tester) async {
      expect(await textsIn(tester, const Locale("ar")), isA<ArabicTexts>());
      expect(await textsIn(tester, const Locale("ar", "EG")), isA<ArabicTexts>());
      expect((await textsIn(tester, const Locale("fr"))).done, "Done");
      expect((await textsIn(tester, null)).done, "Done");
    });
  });

  test("a shipped language takes single strings", () {
    const texts = ArabicTexts(done: "خلاص");
    expect(texts.done, "خلاص");
    expect(texts.gallery, const ArabicTexts().gallery);
    expect(PickerTexts.languages.keys, ["en", "ar"]);
  });
}
