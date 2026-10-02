import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/services/cache_service.dart';
import 'package:image_picker_plus/src/services/camera_service.dart';
import 'package:image_picker_plus/src/services/gallery_service.dart';
import 'package:image_picker_plus/src/services/image_service.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';
import 'package:image_picker_plus/src/settings/picker_texts.dart';
import 'package:image_picker_plus/src/settings/picker_theme.dart';

class PickerServices {
  final GalleryService gallery;

  /// a new one per camera page, since it holds the native camera.
  final CameraService Function() camera;
  final ImageService image;

  /// null when caching is off.
  final CacheService? cache;

  const PickerServices({required this.gallery, required this.camera, required this.image, this.cache});
}

class PickerScope extends InheritedWidget {
  final PickerSettings settings;
  final PickerTheme theme;
  final PickerServices services;

  const PickerScope({
    required this.settings,
    required this.theme,
    required this.services,
    required super.child,
    super.key,
  });

  PickerTexts get texts => settings.texts;

  /// the same scope for a new route or sheet, they're outside this tree.
  PickerScope wrap(Widget child) =>
      PickerScope(settings: settings, theme: theme, services: services, child: child);

  static PickerScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PickerScope>();
    assert(scope != null, "no PickerScope above this context");
    return scope!;
  }

  @override
  bool updateShouldNotify(PickerScope oldWidget) =>
      settings != oldWidget.settings || theme != oldWidget.theme || services != oldWidget.services;
}
