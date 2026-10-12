import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_route.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/export_item.dart';
import 'package:image_picker_plus/src/files/files_flow.dart';
import 'package:image_picker_plus/src/files/files_picker.dart';
import 'package:image_picker_plus/src/gallery/preselection.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart' as platform;
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';

/// opens the picker, see [pick].
abstract final class ImagePickerPlus {
  /// fakes for tests, used instead of the platform services.
  @visibleForTesting
  static PickerServices? debugServices;

  static bool _picking = false;

  /// null when the user closes the picker.
  /// on web call it straight from the tap, an await before it makes the browser block the file picker.
  /// [selected] opens with an earlier pick selected, in that order and with its edits.
  /// with editing on it opens the edit page with them, the gallery only opens from its plus.
  /// on web and desktop it skips the system picker.
  static Future<List<PickedItem>?> pick(
    BuildContext context, {
    PickerSettings settings = const PickerSettings(),
    List<PickedItem>? selected,
  }) async {
    for (final filter in settings.filters) {
      // a list's length can't be checked in a const constructor, so it's checked here before anything opens
      if (filter.matrix.length != 20) {
        throw ArgumentError.value(
          filter.name,
          "filters",
          "a filter matrix is 20 values (5x4), got ${filter.matrix.length}",
        );
      }
    }
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

    final navigator = Navigator.of(context, rootNavigator: settings.useRootNavigator).push;

    if (!_systemPicker) return navigator(route(PickerHome(selected: selected ?? const [])));
    if (settings.source == PickerSource.camera) return navigator(route(_NotSupported(settings)));

    // a second system picker on top of an open one throws on some desktops
    if (_picking) return null;
    _picking = true;
    try {
      if (selected != null && selected.isNotEmpty) {
        final preselection = await Preselection.resolve(
          services: services,
          settings: settings,
          selected: selected,
        );
        if (!context.mounted) return null;
        if (preselection.skipped && Scaffold.maybeOf(context) != null) {
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(settings.texts.filesSkipped)));
        }
        if (preselection.items.isEmpty) return null;
        return await navigator(route(FilesFlow(preselection: preselection), barrier: theme.barrier));
      }
      // no await before open, browsers only allow it right after the click
      final files = await services.files.open(multi: settings.multi, type: settings.mediaType);
      if (files.isEmpty || !context.mounted) return null;
      if (settings.editing) {
        return await navigator(route(FilesFlow(files: files), barrier: theme.barrier));
      }
      final pick = await FilesPicker(services: services, settings: settings).read(files);
      // the caller may have no scaffold, and a snackbar without one asserts
      if (context.mounted && Scaffold.maybeOf(context) != null) {
        pick.showMessages(ScaffoldMessenger.maybeOf(context), settings);
      }
      if (pick.items.isEmpty) return null;
      final picked = await Future.wait(
        pick.items.map((item) => exportItem(services: services, output: settings.output, item: item)),
      );
      return picked.nonNulls.toList();
    } finally {
      _picking = false;
    }
  }

  /// a phone browser reports android or ios, but web has no photo library.
  static bool get _systemPicker =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS);

  /// deletes the edited images kept by [PickerCache].
  static Future<void> clearCache() => platform.clearCache();
}

class _NotSupported extends StatelessWidget {
  const _NotSupported(this.settings);
  final PickerSettings settings;
  @override
  Widget build(BuildContext context) => MessageView(
    PickerScope.of(context).texts.notSupported,
    onClose: () => Navigator.of(context, rootNavigator: settings.useRootNavigator).pop(),
  );
}
