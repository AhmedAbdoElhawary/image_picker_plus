import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_route.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/x_file.dart';
import 'package:image_picker_plus/src/files/files_flow.dart';
import 'package:image_picker_plus/src/files/files_picker.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart' as platform;
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';

abstract final class ImagePickerPlus {
  /// fakes for tests, used instead of the platform services.
  @visibleForTesting
  static PickerServices? debugServices;

  static bool _picking = false;

  /// null when the user closes the picker.
  /// on web call it straight from the tap, an await before it makes the browser block the file picker.
  static Future<List<PickedItem>?> pick(
    BuildContext context, {
    PickerSettings settings = const PickerSettings(),
  }) async {
    final brightness = settings.alwaysDarkTheme ? Brightness.dark : Theme.of(context).brightness;
    final theme = PickerTheme.resolve(settings.theme, brightness);
    // turned off later, so the old files go
    if (!settings.cache.enabled) unawaited(clearCache());
    final services = debugServices ?? platform.platformServices(settings);
    PickerRoute<List<PickedItem>> route(Widget child, {Color? barrier}) => PickerRoute(
      context: context,
      barrier: barrier,
      builder: (_) => PickerScope(settings: settings, theme: theme, services: services, child: child),
    );
    if (!_systemPicker) return Navigator.of(context).push(route(const PickerHome()));
    if (settings.source == PickerSource.camera) {
      return Navigator.of(context).push(route(const _NotSupported()));
    }
    // a second system picker on top of an open one throws on some desktops
    if (_picking) return null;
    _picking = true;
    try {
      // no await before open, browsers only allow it right after the click
      final files = await services.files.open(multi: settings.multi, type: settings.mediaType);
      if (files.isEmpty || !context.mounted) return null;
      if (settings.editing) {
        return await Navigator.of(context).push(route(FilesFlow(files: files), barrier: theme.barrier));
      }
      final pick = await FilesPicker(services: services, settings: settings).read(files);
      // the caller may have no scaffold, and a snackbar without one asserts
      if (context.mounted && Scaffold.maybeOf(context) != null) {
        pick.showMessages(ScaffoldMessenger.maybeOf(context), settings);
      }
      if (pick.items.isEmpty) return null;
      return [
        for (final item in pick.items)
          PickedItem(
            file: XFile(item.path!, name: item.name),
            type: item.type,
            width: item.width,
            height: item.height,
            edited: false,
          ),
      ];
    } finally {
      _picking = false;
    }
  }

  /// a phone browser reports android or ios, but web has no photo library.
  static bool get _systemPicker =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS);

  static Future<void> clearCache() => platform.clearCache();
}

class _NotSupported extends StatelessWidget {
  const _NotSupported();

  @override
  Widget build(BuildContext context) =>
      MessageView(PickerScope.of(context).texts.notSupported, onClose: () => Navigator.of(context).pop());
}
