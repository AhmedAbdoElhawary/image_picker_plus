import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/settings/output_options.dart';

abstract class ImageService {
  /// [cacheKey] names the same edit of the same image, used when caching is on.
  Future<PickedItem> export(
    XFile source,
    EditState state,
    List<double> colorMatrix,
    OutputOptions output, {
    String? cacheKey,
  });
}
