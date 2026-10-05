import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/camera/camera_tools.dart';

void main() {
  test("quick zoom levels from the camera range", () {
    expect(quickLevels(1, 1), isEmpty);
    expect(quickLevels(1, 1.05), isEmpty);
    // only 1x would show, one level hides the row
    expect(quickLevels(1, 1.8), isEmpty);
    expect(quickLevels(1, 2), [1, 2]);
    expect(quickLevels(1, 8), [1, 2, 8]);
    expect(quickLevels(0.6, 10), [0.6, 1, 2, 10]);
    expect(quickLevels(0.4, 5.5), [0.5, 1, 2, 5]);
  });
}
