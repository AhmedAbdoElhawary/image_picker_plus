import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/edit_frame.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';

import '../fakes/pump_picker.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => const SizedBox.expand(key: Key("child"));
}

void main() {
  final child = find.byKey(const Key("child"));

  testWidgets("a wide window gets a centered card", (tester) async {
    await pumpPicker(tester, const EditFrame(child: _Counter()), size: const Size(1440, 900));
    final rect = tester.getRect(child);
    expect(rect.width, PickerLayout.cardMaxWidth);
    expect(rect.height, 900 - PickerLayout.cardMargin * 2);
    expect(rect.center, const Offset(720, 450));
    expect(find.ancestor(of: child, matching: find.byType(ClipRRect)), findsOneWidget);
  });

  testWidgets("a narrow window gets the full page", (tester) async {
    await pumpPicker(tester, const EditFrame(child: _Counter()), size: const Size(599, 800));
    expect(tester.getRect(child), const Rect.fromLTWH(0, 0, 599, 800));
    expect(find.ancestor(of: child, matching: find.byType(ClipRRect)), findsNothing);
  });

  testWidgets("crossing the breakpoint keeps the page state", (tester) async {
    await pumpPicker(tester, const EditFrame(child: _Counter()), size: const Size(1440, 900));
    tester.state<_CounterState>(find.byType(_Counter)).count = 3;
    tester.view.physicalSize = const Size(500, 900);
    await tester.pumpAndSettle();
    expect(tester.getRect(child).width, 500);
    expect(tester.state<_CounterState>(find.byType(_Counter)).count, 3);
  });
}
