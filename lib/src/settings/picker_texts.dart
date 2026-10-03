class PickerTexts {
  final String gallery;
  final String photo;
  final String video;
  final String next;

  /// next in the gallery when it's opened from the edit page to add more.
  final String add;
  final String done;
  final String close;
  final String recent;
  final String noImages;
  final String noCamera;
  final String accessDenied;
  final String cameraDenied;
  final String noMicrophone;
  final String openSettings;
  final String manageAccess;

  /// `{max}` is replaced with the max selection.
  final String maxReached;
  final String videoNotEditable;
  final String notSupported;
  final String crop;
  final String original;
  final String select;
  final String cancel;
  final String switchCamera;
  final String flash;
  final String capture;
  final String processing;
  final String exportFailed;

  /// `{max}` is replaced with the max selection.
  final String maxKept;
  final String filesSkipped;

  /// one name per filter, in the same order.
  final List<String> filterNames;

  /// january first, shown with the year while scrolling the gallery.
  final List<String> months;

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
    this.processing = "Processing",
    this.exportFailed = "Couldn't save the images, try again",
    this.maxKept = "Only the first {max} were kept",
    this.filesSkipped = "Some files couldn't be opened",
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

  String maxReachedFor(int max) => maxReached.replaceAll("{max}", "$max");

  String maxKeptFor(int max) => maxKept.replaceAll("{max}", "$max");

  String monthOf(DateTime date) => "${months[date.month - 1]} ${date.year}";
}
