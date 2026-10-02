import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/edit/crop_view.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

import '../fakes/pump_picker.dart';

void main() {
  late CropController controller;
  setUp(() => controller = CropController(imageAspect: 1, ratio: CropRatio.square));
  tearDown(() => controller.dispose());

  Future<Offset> pump(WidgetTester tester) async {
    await pumpPicker(tester, CropView(controller: controller, image: const SizedBox.expand()));
    return tester.getCenter(find.byType(CropView));
  }

  testWidgets("the mouse wheel zooms around the pointer", (tester) async {
    final center = await pump(tester);
    final point = center + const Offset(100, 0);
    await tester.sendEventToBinding(PointerScrollEvent(position: point, scrollDelta: const Offset(0, -100)));
    await tester.pump();
    expect(controller.zoom, greaterThan(1));
    // the point under the pointer stays where it was, at 3/4 of the width
    final rect = controller.value;
    expect(rect.left + rect.width * 0.75, closeTo(0.75, 0.001));
  });

  testWidgets("a trackpad scroll moves the crop", (tester) async {
    final center = await pump(tester);
    controller.zoomTo(2);
    final before = controller.value;
    await tester.sendEventToBinding(
      PointerScrollEvent(position: center, kind: PointerDeviceKind.trackpad, scrollDelta: const Offset(40, 0)),
    );
    await tester.pump();
    expect(controller.value.left, greaterThan(before.left));
    expect(controller.zoom, closeTo(2, 0.001));
  });

  testWidgets("a web pinch zooms", (tester) async {
    final center = await pump(tester);
    await tester.sendEventToBinding(PointerScaleEvent(position: center, scale: 1.5));
    await tester.pump();
    expect(controller.zoom, closeTo(1.5, 0.001));
  });
}
