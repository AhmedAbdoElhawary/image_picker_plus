import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

class FilesPick {
  /// in the order the system picker returned them, cut to the max.
  final List<MediaItem> items;

  /// more than the max were picked.
  final bool cut;

  /// one or more couldn't be read.
  final bool skipped;

  const FilesPick({required this.items, required this.cut, required this.skipped});

  void showMessages(ScaffoldMessengerState? messenger, PickerSettings settings) {
    if (messenger == null) return;
    if (cut) {
      messenger.showSnackBar(SnackBar(content: Text(settings.texts.maxKeptFor(settings.maxSelection))));
    }
    if (skipped) messenger.showSnackBar(SnackBar(content: Text(settings.texts.filesSkipped)));
  }
}

/// what comes after the system picker, for the first pick and every pick again.
class FilesPicker {
  final PickerServices services;
  final PickerSettings settings;

  const FilesPicker({required this.services, required this.settings});

  /// [room] is how many more fit, the max when nothing is picked yet.
  Future<FilesPick> read(List<XFile> files, {int? room}) async {
    // cut before reading, so a skipped file doesn't pull in one past the max
    final kept = files.take(room ?? settings.maxSelection).toList();
    final items = <MediaItem>[];
    for (final file in kept) {
      final item = await services.files.read(file);
      if (item != null) items.add(item);
    }
    return FilesPick(items: items, cut: files.length > kept.length, skipped: items.length < kept.length);
  }
}
