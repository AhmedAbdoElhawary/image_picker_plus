
<h1 align="left">Image picker plus</h1>

When you try to add a package (like image_picker) to pick an image from a gallery/camera, you will face a lot of issues like:-
- If your app supports multi-themes image picker will not respond with that.
- If your app supports multi-languages image picker will not respond with that.
- If your app has a beautiful design and a good user experience, image_picker will break all of this, Because image_picker has a traditional UI of Gallery display.

In (image_picker_plus), we solve all those issues and many other features like:-
- You can customize the UI of displaying the gallery.
- You can crop the selected image(s) with different aspect ratios.
- You can display photos and videos and choose from both of them.
- You can display a gallery, camera, and video, and the user can choose between them.

<p>
<img src="https://user-images.githubusercontent.com/88978546/189904623-ba086e4e-7f0c-4a3b-ae63-0f2c5276bd08.jpg"    width="70%" height="40%">

</p>
<!-- <p>
<img src="https://user-images.githubusercontent.com/88978546/189904645-2ff958ed-c23e-4040-ad9a-75136bc3e9c6.jpg"    width="70%" height="40%">

</p> -->
<p>
<img src="https://user-images.githubusercontent.com/88978546/189904669-0b9ca16a-9c75-435d-b5a7-82e639153e93.jpg"    width="70%" height="40%">

</p>
<p align="left">
  <a href="https://pub.dartlang.org/packages/image_picker_plus">
    <img src="https://img.shields.io/pub/v/image_picker_plus.svg"
      alt="Pub Package" />
  </a>
    <a href="LICENSE">
    <img src="https://img.shields.io/apm/l/atomic-design-ui.svg?"
      alt="License: MIT" />
  </a> 
</p>


# Installing

## IOS

\* The minimum iOS version is 13.

Add three rows to the `ios/Runner/Info.plist`:

* one with the key `Privacy - Photo Library Usage Description` and a usage description.
* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the key `Privacy - Microphone Usage Description` and a usage description, it's needed to record video with sound.

If editing `Info.plist` as text, add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>your usage description here</string>
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
```

## Android

* The minimum Android sdk version is 24, and compile sdk is Flutter's default. A new Flutter project already has this in `android/app/build.gradle.kts`:

```kotlin
compileSdk = flutter.compileSdkVersion
minSdk = flutter.minSdkVersion
```

* Add these permissions into your AndroidManifest.xml
````xml
<manifest>
    ...
    <application
        android:requestLegacyExternalStorage="true"
    ...
</application>
<uses-permission android:name="android.permission.INTERNET"/>

<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />
    </manifest>
````

### 1. Depend on it

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  image_picker_plus: [last_version]
```

### 2. Install it

You can install packages from the command line:

with `pub`:

```
$ pub get image_picker_plus
```

with `Flutter`:

```
$ flutter pub add image_picker_plus
```

### 3. Import it

In your `Dart` code, you can use:

```dart
import 'package:image_picker_plus/image_picker_plus.dart';
```