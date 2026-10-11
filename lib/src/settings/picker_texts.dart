import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/settings/languages/arabic_texts.dart';

/// every text the picker shows, english by default. [ArabicTexts] ships too.
class PickerTexts {
  /// the gallery tab.
  final String gallery;

  /// the photo tab.
  final String photo;

  /// the video tab.
  final String video;

  /// leaves the gallery for the edit page.
  final String next;

  /// next in the gallery when it's opened from the edit page to add more.
  final String add;

  /// finishes the pick.
  final String done;

  /// closes the picker.
  final String close;

  /// the album with every item.
  final String recent;

  /// an empty album.
  final String noImages;

  /// a device with no camera.
  final String noCamera;

  /// the gallery when photo access is denied.
  final String accessDenied;

  /// the camera when access is denied.
  final String cameraDenied;

  /// a video when microphone access is denied.
  final String noMicrophone;

  /// opens the app's settings from a denied state.
  final String openSettings;

  /// picks more photos when ios access is limited.
  final String manageAccess;

  /// a video that can't be previewed on this platform.
  final String videoPreviewNotSupported;

  /// `{max}` is replaced with the max selection.
  final String maxReached;

  /// a video on the edit page.
  final String videoNotEditable;

  /// a source this platform doesn't have.
  final String notSupported;

  /// the ratio button.
  final String crop;

  /// the image's own ratio.
  final String original;

  /// starts picking more than one.
  final String select;

  /// stops picking more than one.
  final String cancel;

  /// front and back camera.
  final String switchCamera;

  /// the flash button.
  final String flash;

  /// the shutter button.
  final String capture;

  /// while edited images are saved.
  final String processing;

  /// when saving the edited images fails.
  final String exportFailed;

  /// `{max}` is replaced with the max selection.
  final String maxKept;

  /// when some files from an earlier pick or the system picker couldn't be read.
  final String filesSkipped;

  /// the timer button.
  final String timer;

  /// the timer button when it's off.
  final String timerOff;

  /// `{seconds}` is replaced with the timer seconds.
  final String timerSeconds;

  /// the grid button.
  final String grid;

  /// `{zoom}` is replaced with the zoom level.
  final String zoomLevel;

  /// the text tool.
  final String text;

  /// the pen.
  final String draw;

  /// the emoji tool.
  final String emojis;

  /// takes back the last markup change.
  final String undo;

  /// puts back what undo took.
  final String redo;

  /// removes drawn lines.
  final String eraser;

  /// the area a text or emoji is dragged to, to delete it.
  final String delete;

  /// the font switch of a text.
  final String font;

  /// the background switch of a text.
  final String textBackground;

  /// the color row.
  final String color;

  /// the pen sizes.
  final String size;

  /// leaves the markup mode.
  final String doneEditing;

  /// turns the image left.
  final String rotate;

  /// mirrors the image.
  final String flip;

  /// the filters side of the edit page's switch.
  final String filters;

  /// the sliders side of the edit page's switch.
  final String adjust;

  /// a slider.
  final String brightness;

  /// a slider.
  final String contrast;

  /// a slider.
  final String saturation;

  /// a slider.
  final String warmth;

  /// puts a slider back at 0.
  final String reset;

  /// one name per filter, in the same order.
  final List<String> filterNames;

  /// january first, shown with the year while scrolling the gallery.
  final List<String> months;

  /// the english texts, pass any one by name to change it.
  const PickerTexts({
    this.gallery = "Gallery",
    this.photo = "Photo",
    this.video = "Video",
    this.next = "Next",
    this.add = "Add",
    this.done = "Done",
    this.close = "Close",
    this.recent = "Recent",
    this.noImages = "There are no images",
    this.noCamera = "There is no camera",
    this.videoPreviewNotSupported =
        "Video preview not available for this device,\nbut it will be exported normally.",
    this.accessDenied = "Allow access to your photos to continue",
    this.cameraDenied = "Allow camera access to continue",
    this.noMicrophone = "Allow microphone access to record sound",
    this.openSettings = "Open settings",
    this.manageAccess = "Manage access",
    this.maxReached = "You can select up to {max} items",
    this.videoNotEditable = "Videos can only be reordered",
    this.notSupported = "This platform is not supported yet",
    this.crop = "Crop",
    this.original = "Original",
    this.select = "Select",
    this.cancel = "Cancel",
    this.switchCamera = "Switch camera",
    this.flash = "Flash",
    this.capture = "Capture",
    this.processing = "Processing...",
    this.exportFailed = "Couldn't save the images, try again",
    this.maxKept = "Only the first {max} were kept",
    this.filesSkipped = "Some files couldn't be opened",
    this.timer = "Timer",
    this.timerOff = "Timer off",
    this.timerSeconds = "Timer {seconds} seconds",
    this.grid = "Grid",
    this.zoomLevel = "Zoom {zoom}x",
    this.text = "Text",
    this.draw = "Draw",
    this.emojis = "Emojis",
    this.undo = "Undo",
    this.redo = "Redo",
    this.eraser = "Eraser",
    this.delete = "Drag here to delete",
    this.font = "Font",
    this.textBackground = "Background",
    this.color = "Color",
    this.size = "Size",
    this.doneEditing = "Done",
    this.rotate = "Rotate",
    this.flip = "Flip",
    this.filters = "Filters",
    this.adjust = "Adjust",
    this.brightness = "Brightness",
    this.contrast = "Contrast",
    this.saturation = "Saturation",
    this.warmth = "Warmth",
    this.reset = "Reset",
    this.filterNames = const [
      "Normal",
      "Warm",
      "Cool",
      "Vintage",
      "Glamour",
      "Dramatic",
      "Soft",
      "Sepia",
      "Teal",
      "Bright",
      "Contrast",
      "Fade",
      "Mono",
      "Noir",
    ],
    this.months = const [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ],
  });

  /// the shipped languages by language code. a new language is one file and one line here.
  static const Map<String, PickerTexts> languages = {"en": PickerTexts(), "ar": ArabicTexts()};

  /// the shipped language of the app's locale, english when it isn't shipped or there's no locale.
  static PickerTexts of(BuildContext context) =>
      languages[Localizations.maybeLocaleOf(context)?.languageCode] ?? const PickerTexts();

  /// [maxReached] with the number in.
  String maxReachedFor(int max) => maxReached.replaceAll("{max}", "$max");

  /// [maxKept] with the number in.
  String maxKeptFor(int max) => maxKept.replaceAll("{max}", "$max");

  /// [timerSeconds] with the number in.
  String timerSecondsFor(int seconds) => timerSeconds.replaceAll("{seconds}", "$seconds");

  /// [zoomLevel] with the zoom in.
  String zoomLevelFor(String zoom) => zoomLevel.replaceAll("{zoom}", zoom);

  /// the month and year of [date], for the gallery scrollbar.
  String monthOf(DateTime date) => "${months[date.month - 1]} ${date.year}";
}
