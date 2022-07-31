
<h1 align="left">Custom Gallery Display</h1>

When you try to add a package to select an image from a gallery, you will face a bad user experience because you have a traditional UI of Gallery display.

I have two main views of the gallery to solve this issue:
- It looks like the Instagram gallery.
- It's a grid view of gallery images.

You can even customize a display of a camera to take a photo and video from two perspectives

<p align="left">
  <a href="https://pub.dartlang.org/packages/custom_gallery_display">
    <img src="https://img.shields.io/pub/v/custom_gallery_display.svg"
      alt="Pub Package" />
  </a>
    <a href="LICENSE">
    <img src="https://img.shields.io/apm/l/atomic-design-ui.svg?"
      alt="License: MIT" />
  </a> 
</p>

## Necessary note

#### `CustomGallery` is a page that you need to push to it .It's has scafold, you cannot add it as a widget with another scafold

# Installing

## IOS

\* The camera plugin compiles for any version of iOS, but its functionality
requires iOS 10 or higher. If compiling for iOS 9, make sure to programmatically
check the version of iOS running on the device before using any camera plugin features.
The [device_info_plus](https://pub.dev/packages/device_info_plus) plugin, for example, can be used to check the iOS version.

Add two rows to the `ios/Runner/Info.plist`:

* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the key `Privacy - Microphone Usage Description` and a usage description.

If editing `Info.plist` as text, add:

```xml
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
```

## Android

Change the minimum Android sdk version to 21 (or higher), and compile sdk to 31 (or higher) in your `android/app/build.gradle` file.

```java
compileSdkVersion 32
minSdkVersion 21
```

### 1. Depend on it

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  custom_gallery_display: [last_version]
```

### 2. Install it

You can install packages from the command line:

with `pub`:

```
$ pub get custom_gallery_display
```

with `Flutter`:

```
$ flutter pub add custom_gallery_display
```
### 3. Set it

Now in your `main.dart`, put those permissions:

```dart
  WidgetsFlutterBinding.ensureInitialized();
  await CustomGalleryPermissions.requestPermissionExtend();
  ```

### 4. Import it

In your `Dart` code, you can use:

```dart
import 'package:custom_gallery_display/custom_gallery_display.dart';
```
# Usage

It has many configurable properties, including:

- `appTheme` – Customization of colors If you have diffrent themes
- `tabsTexts` – Changing the names of tabs or even thier languages
- `enableCamera` – If you want to take photo from camera (front,back)
- `enableVideo` – If you want to record video from camera (front,back)
- `cropImage` – If you want crop image with aspect ratio that you are selected
- `gridDelegate` – Customization of grid view

There are also callback:

- `sendRequestFunction` – It's function that return to you info about selected image/s

# Examples
<p>
<img src="https://user-images.githubusercontent.com/88978546/173692850-21ab4cab-abd5-4f68-85e7-c010d13b391e.gif"   width="50%" height="50%">

</p>

```dart
/// Remember:
/// CustomGallery is a page that you need to push to it .It's has scafold, you cannot add it as a widget with another scafold

CustomGallery.instagramDisplay(
              cropImage: true, // It's true by default
              enableCamera: true, // It's true by default
              enableVideo: true, // It's true by default
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 1.7,
                mainAxisSpacing: 1.5,
              ), // It's by default
                sendRequestFunction: (SelectedImagesDetails details) async {
                // You can take this variables and push to another page
                bool multiSelectionMode = details.multiSelectionMode;
                bool isThatImage = details.isThatImage;
                List<File>? selectedFiles = details
                    .selectedFiles; // If there one image selected it will be null
                File selectedFile = details.selectedFile;
                double aspectRatio = details.aspectRatio;
              },
            )
```

<p>
<img src="https://user-images.githubusercontent.com/88978546/173691000-0b9db0fa-504e-428c-acdf-7b1ab414dcf9.jpg"    width="25%" height="50%">

</p>


```dart
/// Remember:
/// CustomGallery is a page that you need to push to it .It's has scafold, you cannot add it as a widget with another scafold

CustomGallery.normalDisplay(
              enableCamera: false, // It's false by default
              enableVideo: false, // It's false by default
              appTheme: AppTheme(
                  focusColor: Colors.black, primaryColor: Colors.white),
                sendRequestFunction: (SelectedImagesDetails details) async {
                // You can take this variables and push to another page
                bool multiSelectionMode = details.multiSelectionMode;
                bool isThatImage = details.isThatImage;
                List<File>? selectedFiles = details
                    .selectedFiles; // If there one image selected it will be null
                File selectedFile = details.selectedFile;
                double aspectRatio = details.aspectRatio;
              },
            )
```

<p>
<img src="https://user-images.githubusercontent.com/88978546/173691016-f5b968ae-545e-4efc-81ff-405873678869.jpg"   width="25%" height="50%">
<img src="https://user-images.githubusercontent.com/88978546/173691025-5be932e0-0e1d-42c8-b88f-cff0606dd0d1.jpg"    width="25%" height="50%">

</p>

```dart
/// Remember:
/// CustomGallery is a page that you need to push to it .It's has scafold, you cannot add it as a widget with another scafold

CustomGallery.normalDisplay(
              enableVideo: true,
              appTheme: AppTheme(
                  focusColor: Colors.white, primaryColor: Colors.black),
                tabsTexts: TabsTexts(
                videoText: "فيديو",
                galleryText: "المعرض",
                deletingText: "حذف",
                clearImagesText: "الغاء الصور المحدده",
                limitingText: "اقصي حد للصور هو 10",
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 1.7,
                mainAxisSpacing: 1.5,
              ),
              sendRequestFunction: (_) async {},
            )
```
<p>
<img src="https://user-images.githubusercontent.com/88978546/173691042-d585a6da-cde6-4f7d-b228-f1384b36ea98.jpg"   width="25%" height="50%">

</p>

```dart
/// Remember:
/// CustomGallery is a page that you need to push to it .It's has scafold, you cannot add it as a widget with another scafold

CustomGallery.normalDisplay(
                enableVideo: true,
                enableCamera: true,
                appTheme: AppTheme(
                    focusColor: Colors.white, primaryColor: Colors.black),
                tabsTexts: TabsTexts(
                    videoText: "視頻",
                    photoText: "照片",
                    galleryText: "畫廊",
                    deletingText: "刪除",
                    clearImagesText: "清除所選圖像",
                    limitingText: "限制為 10 張照片或視頻",
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1.7,
                    mainAxisSpacing: 1.5,
                    childAspectRatio: .5,
                ),
                sendRequestFunction: (_) async {},
              )
```

