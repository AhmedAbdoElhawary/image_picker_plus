import 'package:photo_manager/photo_manager.dart';

class CustomGalleryPermissions {
  static Future<PermissionState> requestPermissionExtend() async {
    return await PhotoManager.requestPermissionExtend();
  }
}
