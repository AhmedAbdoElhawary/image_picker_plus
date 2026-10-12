/// keeps edited images on disk, so the same edit again is instant. phones only.
class PickerCache {
  /// off by default.
  final bool enabled;

  /// the oldest files go past this, 100 mb by default.
  final int maxBytes;

  /// off, 100 mb when on.
  const PickerCache({this.enabled = false, this.maxBytes = 100 * 1024 * 1024}) : assert(maxBytes > 0);
}
