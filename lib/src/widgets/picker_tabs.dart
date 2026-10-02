import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/settings/picker_settings.dart';

enum PickerTab { gallery, photo, video }

class PickerTabs extends StatelessWidget {
  final List<PickerTab> tabs;
  final PickerTab current;
  final ValueChanged<PickerTab> onChanged;

  const PickerTabs({required this.tabs, required this.current, required this.onChanged, super.key});

  static List<PickerTab> of(PickerSettings settings) {
    final camera = [
      if (settings.mediaType != MediaType.video) PickerTab.photo,
      if (settings.mediaType != MediaType.image) PickerTab.video,
    ];
    return switch (settings.source) {
      PickerSource.gallery => [PickerTab.gallery],
      PickerSource.camera => camera,
      PickerSource.both => [PickerTab.gallery, ...camera],
    };
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final texts = scope.texts;
    return Material(
      color: scope.theme.background,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final tab in tabs)
              Expanded(
                child: Semantics(
                  selected: tab == current,
                  button: true,
                  child: InkWell(
                    onTap: () => onChanged(tab),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: PickerLayout.pickerTabsHeight),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: PickerDurations.of(context).short,
                          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: tab == current ? scope.theme.onSurface : scope.theme.onSurfaceMuted,
                            fontWeight: tab == current ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(switch (tab) {
                            PickerTab.gallery => texts.gallery,
                            PickerTab.photo => texts.photo,
                            PickerTab.video => texts.video,
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
