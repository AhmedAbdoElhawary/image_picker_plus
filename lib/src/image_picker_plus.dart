import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_route.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/models/picked_item.dart';
import 'package:image_picker_plus/src/services/cache_service_impl.dart';
import 'package:image_picker_plus/src/services/camera_service_impl.dart';
import 'package:image_picker_plus/src/services/gallery_service_impl.dart';
import 'package:image_picker_plus/src/services/image_service_impl.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';
import 'package:image_picker_plus/src/widgets/message_view.dart';
import 'package:image_picker_plus/src/widgets/picker_home.dart';

abstract final class ImagePickerPlus {
  /// fakes for tests, used instead of the platform services.
  @visibleForTesting
  static PickerServices? debugServices;

  /// null when the user closes the picker.
  static Future<List<PickedItem>?> pick(BuildContext context, {PickerSettings settings = const PickerSettings()}) {
    final theme = PickerTheme.resolve(settings.theme, Theme.of(context).brightness);
    // turned off later, so the old files go
    if (!settings.cache.enabled) unawaited(clearCache());
    final services = debugServices ?? _platformServices(settings);
    return Navigator.of(context).push<List<PickedItem>>(
      PickerRoute(
        context: context,
        builder: (_) => PickerScope(
          settings: settings,
          theme: theme,
          services: services,
          child: _supported ? const PickerHome() : const _NotSupported(),
        ),
      ),
    );
  }

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> clearCache() => CacheServiceImpl(maxBytes: 1).clear();

  static PickerServices _platformServices(PickerSettings settings) {
    final cache = settings.cache.enabled ? CacheServiceImpl(maxBytes: settings.cache.maxBytes) : null;
    return PickerServices(
      gallery: GalleryServiceImpl(),
      camera: CameraServiceImpl.new,
      image: ImageServiceImpl(cache: cache),
      cache: cache,
    );
  }
}

class _NotSupported extends StatelessWidget {
  const _NotSupported();

  @override
  Widget build(BuildContext context) =>
      MessageView(PickerScope.of(context).texts.notSupported, onClose: () => Navigator.of(context).pop());
}
