import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

/// the system file picker, used on web and desktop.
abstract class FilesService {
  /// empty when the user cancels. call it straight from a tap or key handler, browsers block it after an await.
  Future<List<XFile>> open({required bool multi, required MediaType type});

  /// null when it can't be read as the type it claims.
  Future<MediaItem?> read(XFile file);
}
