import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/camera/camera_page.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/gallery/gallery_page.dart';
import 'package:image_picker_plus/src/widgets/picker_tabs.dart';

/// the root of the picker: one page, or the pages with tabs under them.
class PickerHome extends StatefulWidget {
  const PickerHome({super.key});

  @override
  State<PickerHome> createState() => _PickerHomeState();
}

class _PickerHomeState extends State<PickerHome> {
  PickerTab? _current;

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final tabs = PickerTabs.of(scope.settings);
    final current = _current ?? tabs.first;
    final hasGallery = tabs.contains(PickerTab.gallery);
    return ColoredBox(
      color: scope.theme.background,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // the gallery stays alive so its selection survives a trip to the camera
                if (hasGallery)
                  Offstage(
                    offstage: current != PickerTab.gallery,
                    child: TickerMode(enabled: current == PickerTab.gallery, child: const GalleryPage()),
                  ),
                // the camera is built only while shown, so it's released when leaving.
                // no fade, two camera pages at once fight over the one camera
                if (current != PickerTab.gallery) CameraPage(key: ValueKey(current), video: current == PickerTab.video),
              ],
            ),
          ),
          if (tabs.length > 1)
            PickerTabs(tabs: tabs, current: current, onChanged: (tab) => setState(() => _current = tab)),
        ],
      ),
    );
  }
}
