import 'package:cross_file/cross_file.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class PickedItem {
  /// the original file, or the edited jpeg.
  final XFile file;

  /// image or video.
  final MediaType type;
  final int width;
  final int height;

  /// true when cropped or filtered.
  final bool edited;

  const PickedItem({
    required this.file,
    required this.type,
    required this.width,
    required this.height,
    required this.edited,
  });
}
