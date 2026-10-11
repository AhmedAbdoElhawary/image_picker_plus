import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/image_picker_plus.dart';
import 'package:image_picker_plus/src/settings/languages/arabic_texts.dart';
import 'package:image_picker_plus/src/settings/picker_filter.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';

void main() {
  test("the shipped ones are 13 looks named by the texts", () {
    expect(PickerFilter.all, hasLength(13));
    for (final filter in PickerFilter.all) {
      expect((filter.name, filter.matrix.length), (null, 20));
    }
    expect(PickerFilter.all.first.nameIn(const PickerTexts()), "Warm");
    expect(PickerFilter.all.last.nameIn(const ArabicTexts()), "أسود");
    expect(const PickerFilter(name: "Brand", matrix: []).nameIn(const ArabicTexts()), "Brand");
  });

  test("a strip index gives Normal at 0 and past the end", () {
    const custom = [PickerFilter(name: "a", matrix: PickerFilter.identity)];
    expect(filterMatrix(PickerFilter.all, 0), PickerFilter.identity);
    expect(filterMatrix(PickerFilter.all, 2), PickerFilter.all[1].matrix);
    expect(filterMatrix(custom, 5), PickerFilter.identity);
  });

  testWidgets("pick throws on a matrix that isn't 20 values, before anything opens", (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox();
          },
        ),
      ),
    );
    await expectLater(
      ImagePickerPlus.pick(
        context,
        settings: const PickerSettings(
          filters: [
            PickerFilter(name: "bad", matrix: [1, 0, 0]),
          ],
        ),
      ),
      throwsA(isA<ArgumentError>().having((error) => error.message, "message", contains("20 values"))),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
