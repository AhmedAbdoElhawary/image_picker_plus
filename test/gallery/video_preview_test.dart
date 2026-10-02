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

  // tests have no video player, like windows and linux
  testWidgets("no player shows the icon and the file name", (tester) async {
    await pumpPicker(tester, VideoPreview(item: video(name: "clip.mp4")));
    expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
    expect(find.text("clip.mp4"), findsOneWidget);
  });

  testWidgets("no name shows only the icon", (tester) async {
    await pumpPicker(tester, VideoPreview(item: video()));
    expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
