class PickerCache {
  final bool enabled;
  final int maxBytes;

  const PickerCache({this.enabled = false, this.maxBytes = 100 * 1024 * 1024}) : assert(maxBytes > 0);
}
