import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/core/selector.dart';

void main() {
  testWidgets("rebuilds only when the selected value changes", (tester) async {
    final notifier = ValueNotifier<int>(1);
    var builds = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Selector<bool>(
          listenable: notifier,
          select: () => notifier.value.isEven,
          builder: (context, even, _) {
            builds++;
            return Text("$even");
          },
        ),
      ),
    );
    expect(builds, 1);

    notifier.value = 3;
    await tester.pump();
    expect(builds, 1);

    notifier.value = 4;
    await tester.pump();
    expect(builds, 2);
    expect(find.text("true"), findsOneWidget);
  });

  testWidgets("moves to a new listenable", (tester) async {
    final first = ValueNotifier<int>(1);
    final second = ValueNotifier<int>(10);
    Widget build(ValueNotifier<int> notifier) => Directionality(
      textDirection: TextDirection.ltr,
      child: Selector<int>(listenable: notifier, select: () => notifier.value, builder: (_, v, _) => Text("$v")),
    );
    await tester.pumpWidget(build(first));
    await tester.pumpWidget(build(second));
    expect(find.text("10"), findsOneWidget);

    second.value = 11;
    await tester.pump();
    expect(find.text("11"), findsOneWidget);
  });

  testWidgets("the child is kept across rebuilds", (tester) async {
    final notifier = ValueNotifier<int>(1);
    const child = Text("same");
    final children = <Widget?>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Selector<int>(
          listenable: notifier,
          select: () => notifier.value,
          builder: (context, value, child) {
            children.add(child);
            return Column(children: [Text("$value"), child!]);
          },
          child: child,
        ),
      ),
    );
    notifier.value = 2;
    await tester.pump();
    expect(find.text("2"), findsOneWidget);
    expect(children, [same(child), same(child)]);
  });
}
