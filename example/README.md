# image_picker_plus example

The full demo with every setting is in [lib/demo.dart](lib/demo.dart). The basic call:

```dart
import 'package:image_picker_plus/image_picker_plus.dart';

final items = await ImagePickerPlus.pick(
  context,
  settings: const PickerSettings(
    source: PickerSource.both,
    mediaType: MediaType.all,
    maxSelection: 10,
    cropRatios: [CropRatio.square, CropRatio.portrait],
    filters: true,
  ),
);
if (items == null) return; // closed

for (final item in items) {
  print("${item.file.path} ${item.type} ${item.width}x${item.height} edited: ${item.edited}");
}
```

Run it with `flutter run` from this folder.
