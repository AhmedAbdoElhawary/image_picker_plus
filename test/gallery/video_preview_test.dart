import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_plus/src/gallery/video_preview.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

import '../fakes/pump_picker.dart';

void main() {
  MediaItem video({String? name}) => MediaItem(
    id: "/picked/clip.mp4",
    path: "/picked/clip.mp4",
    name: name,
    type: MediaType.video,
    width: 0,
    height: 0,
    modified: DateTime(2026),
  );

  const notSupported = "Video preview not available for this device,\nbut it will be exported normally.";

  // tests have no video player, like windows and linux
  testWidgets("no player shows the icon and the message", (tester) async {
    await pumpPicker(tester, VideoPreview(item: video(name: "clip.mp4")));
    expect(find.byIcon(Icons.code_off_rounded), findsOneWidget);
    expect(find.text(notSupported), findsOneWidget);
  });

  testWidgets("no name still shows the message", (tester) async {
    await pumpPicker(tester, VideoPreview(item: video()));
    expect(find.byIcon(Icons.code_off_rounded), findsOneWidget);
    expect(find.text(notSupported), findsOneWidget);
  });
}
