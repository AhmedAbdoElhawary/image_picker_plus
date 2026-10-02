import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/files/files_picker.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/fake_files_service.dart';
import '../fakes/pump_picker.dart';

void main() {
  FilesPicker picker(FakeFilesService files, {int max = 5}) => FilesPicker(
    services: Fakes(files: files).services,
    settings: PickerSettings(maxSelection: max),
  );

  test("keeps every file under the max, in order", () async {
    final pick = await picker(FakeFilesService()).read(FakeFilesService.files(3));
    expect(pick.items.map((item) => item.id), ["/picked/0.jpg", "/picked/1.jpg", "/picked/2.jpg"]);
    expect(pick.cut, isFalse);
    expect(pick.skipped, isFalse);
  });

  test("cuts to the max and says so", () async {
    final pick = await picker(FakeFilesService()).read(FakeFilesService.files(8));
    expect(pick.items.map((item) => item.id), List.generate(5, (index) => "/picked/$index.jpg"));
    expect(pick.cut, isTrue);
  });

  test("skips the unreadable ones and says so", () async {
    final files = FakeFilesService(unreadable: {"/picked/1.jpg"});
    final pick = await picker(files).read(FakeFilesService.files(3));
    expect(pick.items.map((item) => item.id), ["/picked/0.jpg", "/picked/2.jpg"]);
    expect(pick.skipped, isTrue);
  });

  test("cuts before reading, so a skipped file doesn't pull in one past the max", () async {
    final files = FakeFilesService(unreadable: {"/picked/1.jpg"});
    final pick = await picker(files).read(FakeFilesService.files(6));
    expect(pick.items, hasLength(4));
    expect(pick.cut, isTrue);
    expect(pick.skipped, isTrue);
  });

  test("nothing readable gives no items", () async {
    final files = FakeFilesService(unreadable: {"/picked/0.jpg", "/picked/1.jpg"});
    final pick = await picker(files).read(FakeFilesService.files(2));
    expect(pick.items, isEmpty);
    expect(pick.skipped, isTrue);
  });
}
