import 'package:photo_manager/photo_manager.dart';

class ImagePickerPlusPermissions {
  static Future<PermissionState> requestPermissionExtend() async {
    return await PhotoManager.requestPermissionExtend();
  }
}
