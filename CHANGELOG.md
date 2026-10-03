## 1.0.1
* pub.dev lists macOS, Windows and Linux too, the pubspec declares the platforms now
* wasm ready: `video_player` is out of the web build, so a video on web shows its file name like on Windows and Linux
* `cross_file` is no longer a direct dependency, `XFile` comes from `file_selector`. the same class, nothing to change

## 1.0.0
* new API: `ImagePickerPlus.pick(context, settings: PickerSettings(...))` returns `List<PickedItem>?` (breaking, see "Migrating from 0.6.0" in the README)
* no native code anymore, the copied image_crop plugin is removed
* own crop and filters, the result matches the preview and is saved as JPEG with no metadata
* saving the edits runs in a background isolate (decode, crop, filters and encode), with a small processing popup. on web it stays on the engine
* crop in the preview, then filters, reorder and crop again on the edit screen, for many images at once. going back keeps the edits
* camera photos can be cropped too
* the preview slides up under the app bar while scrolling the grid, drag it down or scroll to the top to bring it back. it can be hidden with `showPreview: false`
* the preview and edit images are decoded at the size they're shown, `resizePreview: false` keeps them at 1080 pixels
* ratio menu under the crop button, `CropRatio.all` by default. `cropRatios: []` turns the crop off
* grid columns and cell shape can be set
* camera tabs for photo and video, front/rear, flash, and clear messages when there's no camera or access
* light and dark themes, custom colors and texts, RTL, reduced motion, layouts for phones and tablets
* optional disk cache with a size limit, and `ImagePickerPlus.clearCache()`
* faster gallery: the first 20 show right away and the rest loads 20 at a time behind them, with smaller thumbnails
* fewer dependencies (shimmer and image_picker removed)
* CI for every PR and releases from a version tag
* web, macOS, Windows and Linux: the system file picker opens, then the edit screen with crop, filters and reorder. no gallery or camera there
* the edit screen is a card on wide windows, with mouse wheel and trackpad zoom, drag to reorder, hover, and Esc / Enter / Tab
* a tap picks one image. a long press (with a vibration) or the select button starts counting up to `maxSelection`, cancel goes back to the shown image
* switching album goes back to the top, shows the preview fully with the album's first image
* a plus after the images on the edit screen goes back to pick more (the system picker on web and desktop). they're added last, never past `maxSelection`, and the plus hides at the max
* the plus also adds a photo or video from the camera tabs, and shows with one item too, also after a camera photo
* tap the camera preview to focus and set the exposure there
* a paused video shows a play icon. on the edit screen videos start paused with sound, and a tap plays or pauses
* albums are sorted by the date taken, newest first, and images with no size saved show up too
* a scrollbar with the month and year shows while scrolling the grid, drag it to jump
* the picker is dark by default, `alwaysDarkTheme: false` follows the app brightness
* new texts `maxKept`, `filesSkipped`, `select`, `cancel`, `add` and `months`, and `PickerTheme.barrier`

## 0.6.0
* update dependencies (camera 0.12, shimmer 4, video_player 2.14, photo_manager 3.12, image 4.10, image_picker 1.2.3)
* minimum flutter 3.44 / dart 3.12
* minimum android sdk 24, ios 13
* gallery now works with limited photo access
* update permissions in README (microphone, android 14 selected photos, READ_EXTERNAL_STORAGE for android 12 and below)
* show a message with close button when there is no camera, instead of loading forever
* add close button when there is no images
* fix blank preview sometimes when opening the gallery
* fix preview going back to the first image when more images load

## 0.5.10+1
* handle limit access for ios

## 0.5.10
* update package code

## 0.5.9
* solve camera button bug

## 0.5.8
* solve photo permission bug #56, #68
* solve crop image bugs

## 0.5.7
* solve #63 issue "dependencies bugs"

## 0.5.6+2
* update flutter version

## 0.5.6+1
* handle camera preview

## 0.5.6
* reformat the code
* return callbackFunction

## 0.5.5+3
* add maximumSelection as a parameter

## 0.5.5+2
* update dependencies

## 0.5.5+1
* solve tab bar bug

## 0.5.5
* refactoring the code

## 0.5.4
* edit video display
* add CI/CD

## 0.5.3
* edit video display

## 0.5.2
* update README
* create custom route

## 0.5.1
* update README
* create sendRequestFunction

## 0.5.0
* handle multi selection images bugs

## 0.4.0
* change the way of pick images

## 0.3.9
* update the dependencies
* update README.md

## 0.3.8
* handle crop keys

## 0.3.7
* solve drop frames bug when page view is moving

## 0.3.6
* fix permission bug
* add INTERNET permission in manifest.xml
* update README.md

## 0.3.5
* solve warning of uses or overrides a deprecated API.

## 0.3.4
* solve dropped frames issue in grid view when scrolling
* solve the issue in grid view when the tap bar is moved
* remove the unuseful package

## 0.3.3+1
* reformat the code
## 0.3.3
* rename tabs texts

## 0.3.2
* solve box constraints bug

## 0.3.1
* restructure gallery display
* handling video lag

## 0.2.8
* change the paint color to white

## 0.2.7

* Solve permissions bugs
* Solve camera initializes bugs
* Edit README

## 0.2.6

* Edit README

## 0.2.5

* Ignores deprecation warnings

## 0.2.4

* Solve front camera bugs
* Add some different cases as in example

## 0.2.3

* Solve camera package bugs
* Write a documentation

## 0.2.2

* Add an example to the package

## 0.2.1

* make camera self initialize

## 0.2.0

* Add a normal display
* Solve multi-selection mode bugs