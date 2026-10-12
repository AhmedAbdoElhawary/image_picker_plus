import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';

/// every string of [texts]. a new field needs a line here, like it needs one in each language.
List<String> strings(PickerTexts texts) => [
  texts.gallery,
  texts.photo,
  texts.video,
  texts.next,
  texts.add,
  texts.done,
  texts.close,
  texts.recent,
  texts.noImages,
  texts.noCamera,
  texts.videoPreviewNotSupported,
  texts.accessDenied,
  texts.cameraDenied,
  texts.noMicrophone,
  texts.openSettings,
  texts.somethingWentWrong,
  texts.tryAgain,
  texts.manageAccess,
  texts.maxReached,
  texts.videoNotEditable,
  texts.windowTooSmall,
  texts.notSupported,
  texts.crop,
  texts.original,
  texts.select,
  texts.cancel,
  texts.switchCamera,
  texts.flash,
  texts.capture,
  texts.processing,
  texts.exportFailed,
  texts.maxKept,
  texts.filesSkipped,
  texts.timer,
  texts.timerOff,
  texts.timerSeconds,
  texts.grid,
  texts.zoomLevel,
  texts.text,
  texts.draw,
  texts.emojis,
  texts.undo,
  texts.redo,
  texts.eraser,
  texts.delete,
  texts.font,
  texts.textBackground,
  texts.color,
  texts.size,
  texts.doneEditing,
  texts.rotate,
  texts.flip,
  texts.filters,
  texts.adjust,
  texts.brightness,
  texts.contrast,
  texts.saturation,
  texts.warmth,
  texts.reset,
  texts.strength,
  ...texts.filterNames,
];

/// words these languages really use as they are in english.
const loanwords = {"Video", "Text", "Original", "Normal", "Sepia", "Flash", "Color"};

void main() {
  const english = PickerTexts();

  for (final MapEntry(key: code, value: texts) in PickerTexts.languages.entries) {
    if (code == "en") continue;

    test("$code has every text in its own language", () {
      expect(texts.filterNames.length, english.filterNames.length);
      expect(texts.months.length, 12);
      final own = strings(texts);
      final base = strings(english);
      for (var i = 0; i < base.length; i++) {
        if (!loanwords.contains(own[i])) {
          expect(own[i], isNot(base[i]), reason: "\"${base[i]}\" is still english in $code");
        }
        expect(own[i].trim(), isNotEmpty);
      }
      // german shares some month names with english, so only the whole list is checked
      expect(texts.months, isNot(english.months), reason: "the months are still english in $code");
      expect(texts.months.every((month) => month.trim().isNotEmpty), isTrue);
    });

    test("$code keeps the placeholders", () {
      expect(texts.maxReached, contains("{max}"));
      expect(texts.maxKept, contains("{max}"));
      expect(texts.timerSeconds, contains("{seconds}"));
      expect(texts.zoomLevel, contains("{zoom}"));
    });
  }
}
