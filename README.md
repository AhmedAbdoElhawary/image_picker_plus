
<h1 align="left">Image picker plus</h1>

A picker for images and videos from the gallery or the camera, with a UI that follows your app.

- Gallery with albums, single or multi selection, and a preview.
- Crop in the preview with the ratios you allow, then filters and reorder before returning.
- Camera tabs for photo and video, with front/rear and flash.
- Light and dark themes, your own colors and texts, RTL, and layouts for phones and tablets.
- Optional disk cache for a faster reopen.
- No native code of its own, so there's nothing to set up besides the permissions.

<!-- TODO(ahmed): add new screenshots/gif of 1.0.0 -->

<p align="left">
  <a href="https://pub.dev/packages/image_picker_plus">
    <img src="https://img.shields.io/pub/v/image_picker_plus.svg" alt="Pub Package" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/apm/l/atomic-design-ui.svg?" alt="License: MIT" />
  </a>
</p>

Android and iOS are supported. On web, macOS, Linux and Windows the picker shows a "not supported yet" message.

# Installing

```
flutter pub add image_picker_plus
```

## iOS

The minimum iOS version is 13. Add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>your usage description here</string>
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
```

The microphone is only needed to record videos with sound.

## Android

The minimum Android sdk is 24. Add these permissions to `AndroidManifest.xml`:

```xml
<manifest>
    <application
        android:requestLegacyExternalStorage="true"
        ...>
    </application>

    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />
</manifest>
```

The camera and microphone permissions come from the `camera` plugin.

# Usage

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
    output: OutputOptions(quality: 85, maxWidth: 2048),
    cache: PickerCache(enabled: true),
  ),
);
if (items == null) return; // closed

for (final item in items) {
  print("${item.file.path} ${item.type} ${item.width}x${item.height} edited: ${item.edited}");
}
```

`items` keeps the order the user picked, or the order they set on the edit screen.

## Settings

| Setting | Default | |
|---------|---------|---|
| `source` | `PickerSource.gallery` | `gallery`, `camera` or `both`. With `both` there are tabs for gallery, photo and video |
| `mediaType` | `MediaType.image` | `image`, `video` or `all` |
| `maxSelection` | `1` | `1` is single selection |
| `cropRatios` | `[]` | empty means no crop. Presets: `CropRatio.original`, `square`, `portrait` (4:5), `landscape` (16:9), or `CropRatio(3, 2)`. Only these show in the ratio menu |
| `showPreview` | `true` | `false` hides the preview above the grid. The crop is then only on the edit screen, at the image's own ratio |
| `gridColumns` | `null` | images per row, `null` follows the screen width (4, 6 or 8) |
| `gridCellAspectRatio` | `1` | width / height of a grid cell, `0.5` is twice as tall as wide |
| `filters` | `false` | shows the filters on the edit screen |
| `output` | `OutputOptions()` | JPEG quality (90) and optional max width and height for edited images |
| `theme` | `null` | `null` follows the app brightness with `PickerTheme.light()` / `PickerTheme.dark()` |
| `texts` | `PickerTexts()` | every text the picker shows, English by default |
| `cache` | `PickerCache()` | off by default, see below |

When there's no crop and no filters, next returns the picked items right away. Otherwise next opens the edit screen.

Edited images are returned as new JPEG files with no metadata. Items that weren't edited, and all videos, are returned as the original file.

## Theme and texts

```dart
PickerSettings(
  theme: const PickerTheme(
    background: Color(0xFF0E0E10),
    surface: Color(0xFF1C1C20),
    onSurface: Color(0xFFF4F4F6),
    onSurfaceMuted: Color(0xFF9A9AA4),
    accent: Color(0xFFFF7A00),
    onAccent: Color(0xFFFFFFFF),
    scrim: Color(0xB3000000),
  ),
  texts: const PickerTexts(next: "Weiter", done: "Fertig"),
)
```

## Caching

With `PickerCache(enabled: true, maxBytes: 100 * 1024 * 1024)` thumbnails and edited images are kept on disk in the app's temp folder, and the oldest go first when it's over `maxBytes`. When caching is off nothing is saved, and an old cache folder is removed on the next open.

```dart
await ImagePickerPlus.clearCache();
```

# Migrating from 0.6.0

1.0.0 is a new API. The native crop plugin is gone, so you can also remove any setup you did for it.

| 0.6.0 | 1.0.0 |
|-------|-------|
| `ImagePickerPlus(context).pickImage/pickVideo/pickBoth(source: ...)` | `ImagePickerPlus.pick(context, settings: PickerSettings(mediaType: ..., source: ...))` |
| `ImageSource.gallery/camera/both` | `PickerSource` |
| `GalleryDisplaySettings.maximumSelection` | `PickerSettings.maxSelection` |
| `GalleryDisplaySettings.cropImage` / `showImagePreview` | `cropRatios` / `showPreview` |
| `GalleryDisplaySettings.gridDelegate` | `gridColumns` and `gridCellAspectRatio` |
| `GalleryDisplaySettings.callbackFunction` | removed, `await` the result |
| `multiSelection: true` | `maxSelection > 1` |
| `AppTheme` | `PickerTheme` |
| `TabsTexts` | `PickerTexts` |
| `SelectedImagesDetails` / `SelectedByte` | `List<PickedItem>` |
| Android `minSdk` and iOS setup for the crop plugin | not needed |

Before:

```dart
final details = await ImagePickerPlus(context).pickImage(
  source: ImageSource.gallery,
  multiImages: true,
  galleryDisplaySettings: GalleryDisplaySettings(maximumSelection: 5, cropImage: true),
);
final files = details?.selectedFiles.map((e) => e.selectedFile).toList();
```

After:

```dart
final items = await ImagePickerPlus.pick(
  context,
  settings: const PickerSettings(maxSelection: 5, cropRatios: [CropRatio.square]),
);
final files = items?.map((e) => File(e.file.path)).toList();
```

# Contributing

Run the same checks as the CI before a PR:

```
dart format --output=none --set-exit-if-changed lib test example/lib
flutter analyze --fatal-infos
flutter test --coverage
flutter pub publish --dry-run
```

The CI fails when line coverage is under 80% (the `services/*_impl.dart` files are left out, only a device can run them). For speed numbers, run the profile test in the example on a real device:

```
cd example
flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/gallery_scroll_test.dart
```

## Releasing

1. Bump `version:` in `pubspec.yaml` and add a `## x.y.z` section at the top of `CHANGELOG.md`.
2. Merge to `main`.
3. Push the tag: `git tag vx.y.z && git push origin vx.y.z`.

The release workflow checks the tag against `pubspec.yaml` and `CHANGELOG.md`, publishes to pub.dev and creates the GitHub release with that CHANGELOG section.
