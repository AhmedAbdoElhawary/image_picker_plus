// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_plus/redesign_src/core/utils/random_text.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class Conversions {
  static Future<List<img.Image>?> convertMultiFilesToImg(List<File> image, {bool isolate = true}) async {
    try {
      if (isolate) {
        return await Isolate.run(
          () async {
            return await _convertMultiFilesToImg(image);
          },
        );
      }

      return await _convertMultiFilesToImg(image);
    } catch (e) {
      return null;
    }
  }

  static Future<List<img.Image>?> _convertMultiFilesToImg(List<File> files) async {
    try {
      final futures = files
          .map((file) => _convertFileToImg(file).then(
                (value) => value ?? (throw "invalid"),
              ))
          .toList();

      return await Future.wait(futures);
    } catch (e) {
      return null;
    }
  }

  static Future<File> convertImgToFile(img.Image image, {required String tempCacheSessionUUid}) async {
    return _convertImgToFile(image, tempCacheSessionUUid);
  }

  static Future<img.Image?> convertFileToImg(File file, {bool isolate = true}) async {
    try {
      if (isolate) {
        return await Isolate.run(
          () async {
            return await _convertFileToImg(file);
          },
        );
      }

      return _convertFileToImg(file);
    } catch (e) {
      return null;
    }
  }

  static Future<File> _convertImgToFile(img.Image image, String tempCacheSessionUUid) async {
    List<int> imageBytes = img.encodeJpg(image, quality: 100);

    final exportPhotoPath = await _getPhotoExportPath();
    File file = await _createFile(exportPhotoPath, image, tempCacheSessionUUid);

    return await file.writeAsBytes(imageBytes, flush: true);
  }

  static Future<File> _createFile(
      String exportPhotoPath, img.Image image, String tempCacheSessionUUid) async {
    String directoryPath = path.join(exportPhotoPath, tempCacheSessionUUid);

    final directory = Directory(directoryPath);
    if (!directory.existsSync()) await directory.create(recursive: true);

    String fileName = '${RandomString.generate()}.jpg';
    File file = await File(path.join(directoryPath, fileName)).create();

    return file;
  }

  static Future<img.Image?> _convertFileToImg(File file) async {
    final imageBytes = await file.readAsBytes();

    return img.decodeImage(imageBytes);
  }

  static Future<String> getTempDirectoryPath() async => (await getTempDirectory()).path;

  static Future<Directory> getTempDirectory() async {
    // [searchKeyForGetExternalCacheDirectories]
    // if i use getExternalCacheDirectories i am not able to create inside it photo_exports folder
    // in general dealing with getExternalCacheDirectories is unexpected
    // so, i made it to use getTemporaryDirectory
    if (Platform.isAndroid) {
      final dir = (await getExternalCacheDirectories())?.firstOrNull;
      if (dir == null) return (await getTemporaryDirectory());
      return dir;
    } else if (Platform.isIOS) {
      return (await getTemporaryDirectory());
    } else {
      throw ();
    }
  }

  static Future<String> createPhotoExportPath({required String uuid}) async {
    final Directory exportDir = await _getPhotoExportDirectory(uuid: uuid);
    if (!await exportDir.exists()) await exportDir.create(recursive: true);

    return exportDir.path;
  }

  static Future<String> changePhotoPath({required String photoPath, required String exportPath}) async {
    final File photo = File(photoPath);
    final String fileName = photo.uri.pathSegments.last;
    final File newPhoto = File('$exportPath/$fileName');

    await photo.copy(newPhoto.path);
    unawaited(deletePhotoPath(path: photoPath));

    return newPhoto.path;
  }

  /// this to clear temp cache that created by ImagePicker too
  /// It makes two cache path for the same image, one just under cache dir and one inside folder with random name
  /// so, we cannot detect how to clear it, so we clear all cache except some folders that not belong to it
  static Future<void> clearAllPhotoExports() async {
    try {
      final Directory cacheDir = await getTempDirectory();
      await _clearAllPhotoExports(cacheDir);

      /// as we save the temporary data in getExternalCacheDirectories but in native image picker they save getTemporaryDirectory
      /// so, i clear both in android
      if (Platform.isAndroid) await _clearAllPhotoExports(await getTemporaryDirectory());
    } catch (e) {
      debugPrint('========>>>>>>>>>> Failed to delete files: $e');
    }
  }

  static Future<void> _clearAllPhotoExports(Directory cacheDir) async {
    final String targetFolderName = 'photo_exports';

    if (!await cacheDir.exists()) return debugPrint('Cache directory does not exist.');

    final Directory targetDir = Directory('${cacheDir.path}/$targetFolderName');

    if (await targetDir.exists()) {
      try {
        await targetDir.delete(recursive: true);
        debugPrint('========>>>>>>>>>> Deleted folder: ${targetDir.path}');
      } catch (e) {
        debugPrint('========>>>>>>>>>> Failed to delete folder ${targetDir.path}: $e');
      }
    }
  }

  static Future<String> _getPhotoExportPath() async {
    final tempDir = await getTempDirectory();

    return '${tempDir.path}/photo_exports';
  }

  static Future<Directory> _getPhotoExportDirectory({required String uuid}) async {
    final tempPhotoExportPath = await _getPhotoExportPath();

    final String photoExportPath = '$tempPhotoExportPath/$uuid';

    return Directory(photoExportPath);
  }

  static Future<void> clearSpecificPhotoExports({required String uuid}) async {
    final Directory exportDir = await _getPhotoExportDirectory(uuid: uuid);

    if (await exportDir.exists()) {
      try {
        await exportDir.delete(recursive: true);
        debugPrint('All files under ${exportDir.path} have been deleted.');
      } catch (e) {
        debugPrint('Error while deleting files: $e');
      }
    } else {
      debugPrint('No photo exports directory found.');
    }
  }

  static Future<void> deletePhotoPath({required String path}) async {
    try {
      final tempFile = File(path);

      if (await tempFile.exists()) {
        await tempFile.delete();
        debugPrint('==========>>>>>>> ${tempFile.path} have been deleted.');
        return;
      }
      debugPrint('No photo exports directory found in deletePhotoPath.');
    } catch (e) {
      debugPrint('Error while deleting files in deletePhotoPath: $e');
    }
  }
}
