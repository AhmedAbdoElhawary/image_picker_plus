import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/durations.dart';

void main() {
  Future<PickerDurations> read(WidgetTester tester, {required bool disable}) async {
    late PickerDurations durations;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disable),
        child: Builder(
          builder: (context) {
            durations = PickerDurations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return durations;
  }

  testWidgets("normal durations", (tester) async {
    final durations = await read(tester, disable: false);
    expect(durations.short, const Duration(milliseconds: 150));
    expect(durations.medium, const Duration(milliseconds: 250));
    expect(durations.long, const Duration(milliseconds: 350));
  });

  testWidgets("zero with reduced motion", (tester) async {
    final durations = await read(tester, disable: true);
    expect(durations.short, Duration.zero);
    expect(durations.medium, Duration.zero);
    expect(durations.long, Duration.zero);
  });
}
