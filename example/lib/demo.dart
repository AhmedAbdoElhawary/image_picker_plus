import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/image_picker_plus.dart';

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  bool dark = false;
  bool rtl = false;
  double textScale = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
      ),
      home: Demo(
        dark: dark,
        rtl: rtl,
        textScale: textScale,
        onDark: (value) => setState(() => dark = value),
        onRtl: (value) => setState(() => rtl = value),
        onTextScale: (value) => setState(() => textScale = value),
      ),
    );
  }
}

class Demo extends StatefulWidget {
  final bool dark;
  final bool rtl;
  final double textScale;
  final ValueChanged<bool> onDark;
  final ValueChanged<bool> onRtl;
  final ValueChanged<double> onTextScale;

  const Demo({
    required this.dark,
    required this.rtl,
    required this.textScale,
    required this.onDark,
    required this.onRtl,
    required this.onTextScale,
    super.key,
  });

  @override
  State<Demo> createState() => _DemoState();
}

enum CropChoice { off, squarePortrait, all }

class _DemoState extends State<Demo> {
  PickerSource source = PickerSource.both;
  MediaType mediaType = MediaType.all;
  int maxSelection = 10;
  CropChoice crop = CropChoice.all;
  bool filters = true;
  bool cache = false;
  List<PickedItem> items = const [];

  Future<void> _pick() async {
    final picked = await ImagePickerPlus.pick(
      context,
      settings: PickerSettings(
        source: source,
        mediaType: mediaType,
        maxSelection: maxSelection,
        cropRatios: switch (crop) {
          CropChoice.off => const [],
          CropChoice.squarePortrait => const [CropRatio.square, CropRatio.portrait],
          CropChoice.all => const [
            CropRatio.square,
            CropRatio.portrait,
            CropRatio.landscape,
            CropRatio.original,
          ],
        },
        filters: filters,
        cache: PickerCache(enabled: cache),
      ),
    );
    if (picked != null) setState(() => items = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("image_picker_plus"),
        actions: [
          IconButton(onPressed: ImagePickerPlus.clearCache, icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pick,
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text("Pick"),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: 96),
        children: [
          _Choice<PickerSource>(
            label: "Source",
            value: source,
            values: PickerSource.values,
            onChanged: (value) => setState(() => source = value),
          ),
          _Choice<MediaType>(
            label: "Media",
            value: mediaType,
            values: MediaType.values,
            onChanged: (value) => setState(() => mediaType = value),
          ),
          ListTile(
            title: Text("Max selection: $maxSelection"),
            subtitle: Slider(
              value: maxSelection.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (value) => setState(() => maxSelection = value.round()),
            ),
          ),
          _Choice<CropChoice>(
            label: "Crop",
            value: crop,
            values: CropChoice.values,
            onChanged: (value) => setState(() => crop = value),
          ),
          SwitchListTile(
            title: const Text("Filters"),
            value: filters,
            onChanged: (value) => setState(() => filters = value),
          ),
          SwitchListTile(
            title: const Text("Cache"),
            value: cache,
            onChanged: (value) => setState(() => cache = value),
          ),
          SwitchListTile(title: const Text("Dark"), value: widget.dark, onChanged: widget.onDark),
          SwitchListTile(title: const Text("Right to left"), value: widget.rtl, onChanged: widget.onRtl),
          ListTile(
            title: Text("Text scale: ${widget.textScale.toStringAsFixed(1)}"),
            subtitle: Slider(
              value: widget.textScale,
              min: 0.8,
              max: 2,
              divisions: 12,
              onChanged: widget.onTextScale,
            ),
          ),
          _Results(items),
        ],
      ),
    );
  }
}

class _Choice<T extends Enum> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;

  const _Choice({required this.label, required this.value, required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: SegmentedButton<T>(
        segments: [for (final v in values) ButtonSegment(value: v, label: Text(v.name))],
        selected: {value},
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final List<PickedItem> items;

  const _Results(this.items);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            item.type == MediaType.video
                ? const ColoredBox(color: Colors.black12, child: Icon(Icons.videocam_outlined))
                // on web the path is a blob url
                : kIsWeb
                ? Image.network(item.file.path, fit: BoxFit.cover)
                : Image.file(File(item.file.path), fit: BoxFit.cover),
            PositionedDirectional(
              start: 4,
              bottom: 4,
              child: Text(
                "${index + 1} · ${item.width}x${item.height}${item.edited ? " · edited" : ""}",
                style: const TextStyle(color: Colors.white, fontSize: 10, shadows: [Shadow(blurRadius: 4)]),
              ),
            ),
          ],
        );
      },
    );
  }
}
