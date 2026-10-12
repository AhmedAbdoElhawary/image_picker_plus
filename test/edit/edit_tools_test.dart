import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/edit_page.dart';
import 'package:image_picker_plus/src/edit/image_edits.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/orientation_buttons.dart';
import 'package:image_picker_plus/src/gallery/ratio_button.dart';
import 'package:image_picker_plus/src/models/adjustments.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';
import 'package:image_picker_plus/src/settings/languages/arabic_texts.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_gallery_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  final a = fakeItem("a");
  final b = fakeItem("b");
  final v = fakeItem("v", type: MediaType.video);

  Map<String, ValueNotifier<Adjustments>> slidersOf(List<MediaItem> items) => {
    for (final item in items)
      if (!item.isVideo) item.id: ValueNotifier(Adjustments.neutral),
  };

  group("filters", () {
    testWidgets("custom filters show after Normal with their own names", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [a], filterIndexes: {"a": ValueNotifier(0)}),
        settings: const PickerSettings(
          filters: [
            PickerFilter(name: "Brand", matrix: PickerFilter.identity),
            PickerFilter(name: "Night", matrix: PickerFilter.identity),
          ],
        ),
      );
      expect(find.text("Normal"), findsOneWidget);
      expect(find.text("Brand"), findsOneWidget);
      expect(find.text("Night"), findsOneWidget);
      expect(find.text("Warm"), findsNothing);
    });

    testWidgets("shipped filters take the language's names", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [a], filterIndexes: {"a": ValueNotifier(0)}),
        settings: const PickerSettings(filters: PickerFilter.all, texts: ArabicTexts()),
      );
      expect(find.text("عادي"), findsOneWidget);
      expect(find.text("دافئ"), findsOneWidget);
    });
  });

  group("filter strength", () {
    testWidgets("shows full for a picked filter, a drag lowers it, a new filter starts full", (tester) async {
      final fakes = Fakes();
      final filter = ValueNotifier(0);
      final strength = ValueNotifier(1.0);
      await pumpPicker(
        tester,
        EditPage(items: [a], filterIndexes: {"a": filter}, filterStrengths: {"a": strength}),
        fakes: fakes,
        settings: const PickerSettings(filters: PickerFilter.all),
      );
      expect(find.byType(Slider), findsNothing);

      await tester.tap(find.text("Warm"));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text("100"), findsOneWidget);

      await tester.drag(find.byType(Slider), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(strength.value, lessThan(1));
      expect(find.text("${(strength.value * 100).round()}"), findsOneWidget);

      await tester.tap(find.text("Cool"));
      await tester.pumpAndSettle();
      expect(strength.value, 1);
      await tester.tap(find.text("Normal"));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNothing);

      await tester.tap(find.text("Cool"));
      await tester.pumpAndSettle();
      strength.value = 0.5;
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect(fakes.image.calls.single.$2.filterStrength, 0.5);
      expect(
        fakes.image.matrices.single,
        composeMatrix(filterMatrix(PickerFilter.all, 2, strength: 0.5), Adjustments.neutral),
      );
    });

    testWidgets("sits under the filters and adjust switch, only on filters", (tester) async {
      await pumpPicker(
        tester,
        EditPage(
          items: [a],
          filterIndexes: {"a": ValueNotifier(1)},
          filterStrengths: {"a": ValueNotifier(1.0)},
          adjustments: slidersOf([a]),
        ),
        settings: const PickerSettings(filters: PickerFilter.all, adjustments: true),
      );
      expect(
        tester.getTopLeft(find.byType(Slider)).dy,
        greaterThan(tester.getBottomLeft(find.text("Filters")).dy),
      );
      expect(find.text("100"), findsOneWidget);
      await tester.tap(find.text("Adjust"));
      await tester.pumpAndSettle();
      expect(find.text("100"), findsNothing);
    });
  });

  group("sliders", () {
    const both = PickerSettings(maxSelection: 5, filters: PickerFilter.all, adjustments: true);

    testWidgets("only the sliders on shows no switch", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [a], adjustments: slidersOf([a])),
        settings: const PickerSettings(adjustments: true),
      );
      expect(find.text("Adjust"), findsNothing);
      expect(find.text("Brightness"), findsOneWidget);
    });

    testWidgets("both on shows the switch, filters first", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [a], filterIndexes: {"a": ValueNotifier(0)}, adjustments: slidersOf([a])),
        settings: both,
      );
      expect(find.text("Adjust"), findsOneWidget);
      expect(find.text("Warm"), findsOneWidget);
      await tester.tap(find.text("Adjust"));
      await tester.pumpAndSettle();
      expect(find.text("Brightness"), findsOneWidget);
      expect(find.text("Warm"), findsNothing);
    });

    testWidgets("a slider moves its value, reset puts it back, each image keeps its own", (tester) async {
      final sliders = slidersOf([a, b]);
      await pumpPicker(
        tester,
        EditPage(items: [a, b], adjustments: sliders),
        settings: const PickerSettings(maxSelection: 5, adjustments: true),
      );
      await tester.tap(find.text("Contrast"));
      await tester.pump();
      await tester.drag(find.byType(Slider), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(sliders["a"]!.value.contrast, greaterThan(0));
      expect(sliders["a"]!.value.brightness, 0);
      expect(sliders["b"]!.value, Adjustments.neutral);
      await tester.tap(find.text("Reset"));
      await tester.pumpAndSettle();
      expect(sliders["a"]!.value, Adjustments.neutral);
    });

    testWidgets("reset sits at the end of the switch row and resets only the picked slider", (tester) async {
      final sliders = slidersOf([a]);
      await pumpPicker(
        tester,
        EditPage(items: [a], filterIndexes: {"a": ValueNotifier(0)}, adjustments: sliders),
        settings: both,
      );
      await tester.tap(find.text("Adjust"));
      await tester.pumpAndSettle();
      sliders["a"]!.value = const Adjustments(brightness: 0.4, contrast: 0.3);
      await tester.tap(find.text("Contrast"));
      await tester.pumpAndSettle();
      final reset = tester.getCenter(find.text("Reset"));
      expect(reset.dy, closeTo(tester.getCenter(find.text("Adjust")).dy, 1));
      expect(reset.dx, greaterThan(tester.getCenter(find.text("Adjust")).dx));
      await tester.tap(find.text("Reset"));
      await tester.pumpAndSettle();
      expect(sliders["a"]!.value, const Adjustments(brightness: 0.4));
    });

    testWidgets("the sliders go out composed with the filter", (tester) async {
      final fakes = Fakes();
      final sliders = slidersOf([a]);
      final filter = ValueNotifier(2);
      await pumpPicker(
        tester,
        EditPage(items: [a], filterIndexes: {"a": filter}, adjustments: sliders),
        fakes: fakes,
        settings: both,
      );
      sliders["a"]!.value = const Adjustments(warmth: 0.5);
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      final state = fakes.image.calls.single.$2;
      expect((state.filterIndex, state.adjustments), (2, const Adjustments(warmth: 0.5)));
      expect(
        fakes.image.matrices.single,
        composeMatrix(PickerFilter.all[1].matrix, const Adjustments(warmth: 0.5)),
      );
    });

    testWidgets("every slider back at 0 and Normal gives the original back", (tester) async {
      final fakes = Fakes();
      final sliders = slidersOf([a]);
      Object? result;
      await pumpPicker(
        tester,
        EditPage(items: [a], adjustments: sliders),
        fakes: fakes,
        settings: const PickerSettings(cropRatios: [], adjustments: true),
        onResult: (r) => result = r,
      );
      sliders["a"]!.value = const Adjustments(brightness: 0.4);
      sliders["a"]!.value = Adjustments.neutral;
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      expect(fakes.image.calls, isEmpty);
      expect((result! as List<PickedItem>).single.edited, isFalse);
    });

    testWidgets("a video dims the sliders", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [v, a], adjustments: slidersOf([v, a])),
        settings: const PickerSettings(maxSelection: 5, adjustments: true),
      );
      final ignore = tester.widget<IgnorePointer>(
        find.ancestor(of: find.byType(Slider), matching: find.byType(IgnorePointer)).first,
      );
      expect(ignore.ignoring, isTrue);
    });
  });

  group("rotate and flip", () {
    CropController cropOf(MediaItem item) =>
        CropController(imageAspect: item.width / item.height, ratio: CropRatio.square);

    testWidgets("the buttons turn and flip the crop, and the export gets them", (tester) async {
      final fakes = Fakes();
      final crops = {"a": cropOf(a), "b": cropOf(b)};
      await pumpPicker(
        tester,
        EditPage(items: [a, b], crops: crops),
        fakes: fakes,
        settings: const PickerSettings(maxSelection: 5),
      );
      expect(find.byType(OrientationButtons), findsOneWidget);
      await tester.tap(find.byTooltip("Rotate"));
      await tester.tap(find.byTooltip("Flip"));
      await tester.pump();
      expect((crops["a"]!.turns, crops["a"]!.flipped), (3, true));
      expect((crops["b"]!.turns, crops["b"]!.flipped), (0, false));
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();
      final states = {for (final call in fakes.image.calls) call.$1: call.$2};
      expect((states["/fake/a"]!.turns, states["/fake/a"]!.flipped), (3, true));
    });

    testWidgets("a turn takes the markup with it", (tester) async {
      const text = TextMark(text: "Hi", color: Color(0xFF000000), center: Offset(0.2, 0.1), size: 0.1);
      final edits = ImageEdits()..put("a", crop: cropOf(a), markup: MarkupController()..add(text));
      await pumpPicker(tester, EditPage(items: [a], crops: edits.crops, markups: edits.markups));
      await tester.tap(find.byTooltip("Rotate"));
      await tester.pump();
      final center = (edits.markups["a"]!.value.single as TextMark).center;
      expect(center.dx, closeTo(0.1, 1e-9));
      expect(center.dy, closeTo(0.8, 1e-9));
      edits.markups["a"]!.undo();
      expect(edits.markups["a"]!.value, isEmpty);
    });

    testWidgets("a gallery image gets the ratio button too when there's more than one ratio", (tester) async {
      final crop = cropOf(a);
      await pumpPicker(tester, EditPage(items: [a], crops: {"a": crop}));
      await tester.tap(find.byType(RatioButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text("16:9").last);
      await tester.pumpAndSettle();
      expect(crop.ratio, CropRatio.landscape);
    });

    testWidgets("rotate and flip sit in the middle under the image, the ratio at the start", (tester) async {
      await pumpPicker(tester, EditPage(items: [a], crops: {"a": cropOf(a)}));
      final buttons = tester.getCenter(find.byType(OrientationButtons));
      expect(buttons.dx, closeTo(200, 1));
      expect(tester.getCenter(find.byType(RatioButton)).dx, lessThan(buttons.dx));
    });

    testWidgets("no buttons for a video", (tester) async {
      await pumpPicker(tester, EditPage(items: [v]), settings: const PickerSettings());
      expect(find.byType(OrientationButtons), findsNothing);
    });

    testWidgets("no buttons with the crop off", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [a]),
        settings: const PickerSettings(cropRatios: []),
      );
      expect(find.byType(OrientationButtons), findsNothing);
    });

    testWidgets("rotate off leaves flip alone", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [a], crops: {"a": cropOf(a)}),
        settings: const PickerSettings(rotate: false),
      );
      expect(find.byTooltip("Rotate"), findsNothing);
      expect(find.byTooltip("Flip"), findsOneWidget);
    });

    testWidgets("no buttons with rotate and flip off", (tester) async {
      await pumpPicker(
        tester,
        EditPage(items: [a], crops: {"a": cropOf(a)}),
        settings: const PickerSettings(rotate: false, flip: false),
      );
      expect(find.byType(OrientationButtons), findsNothing);
    });
  });
}
