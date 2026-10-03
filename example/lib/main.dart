import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const DemoApp());

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

enum ThemeChoice { app, custom }

enum TextsChoice { english, arabic }

class _DemoState extends State<Demo> {
  /* CropRatio.all
[
    CropRatio.square,
    CropRatio.portrait,
    CropRatio.landscape,
    CropRatio.original,
    CropRatio(3, 4),
]
*/
  static const List<CropRatio> allRatios = CropRatio.all;

  PickerSource source = PickerSource.both;
  MediaType mediaType = MediaType.all;
  int maxSelection = 10;
  Set<CropRatio> ratios = allRatios.toSet();
  bool showPreview = true;
  bool resizePreview = true;

  /// 0 follows the screen width.
  int gridColumns = 0;
  double gridCellAspectRatio = 1;
  bool filters = true;
  int quality = 90;

  /// 0 keeps the image size.
  int maxWidth = 0;
  int maxHeight = 0;
  ThemeChoice theme = ThemeChoice.app;
  bool alwaysDarkTheme = true;
  TextsChoice texts = TextsChoice.english;
  bool cache = false;
  int cacheMb = 100;
  List<PickedItem> items = const [];

  Future<void> _pick() async {
    final picked = await ImagePickerPlus.pick(
      context,
      settings: PickerSettings(
        source: source,
        mediaType: mediaType,
        maxSelection: maxSelection,
        // the first one is where the crop starts, so keep the list order
        cropRatios: [
          for (final ratio in allRatios)
            if (ratios.contains(ratio)) ratio,
        ],
        showPreview: showPreview,
        resizePreview: resizePreview,
        gridColumns: gridColumns == 0 ? null : gridColumns,
        gridCellAspectRatio: gridCellAspectRatio,
        filters: filters,
        output: OutputOptions(
          quality: quality,
          maxWidth: maxWidth == 0 ? null : maxWidth,
          maxHeight: maxHeight == 0 ? null : maxHeight,
        ),
        theme: theme == ThemeChoice.custom ? customTheme : null,
        alwaysDarkTheme: alwaysDarkTheme,
        texts: texts == TextsChoice.arabic ? arabicTexts : const PickerTexts(),
        cache: PickerCache(enabled: cache, maxBytes: cacheMb * 1024 * 1024),
      ),
    );
    if (picked != null) setState(() => items = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("image_picker_plus"),
        actions: [IconButton(onPressed: ImagePickerPlus.clearCache, icon: const Icon(Icons.delete_sweep_outlined))],
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
          ListTile(
            title: Text("Crop ratios${ratios.isEmpty ? ": off" : ""}"),
            subtitle: Wrap(
              spacing: 8,
              children: [
                for (final ratio in allRatios)
                  FilterChip(
                    label: Text("$ratio"),
                    selected: ratios.contains(ratio),
                    onSelected: (selected) =>
                        setState(() => ratios = selected ? {...ratios, ratio} : ({...ratios}..remove(ratio))),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text("Show preview"),
            value: showPreview,
            onChanged: (value) => setState(() => showPreview = value),
          ),
          SwitchListTile(
            title: const Text("Resize preview"),
            subtitle: const Text("off decodes the preview at 1080 pixels"),
            value: resizePreview,
            onChanged: (value) => setState(() => resizePreview = value),
          ),
          _Choice<int>(
            label: "Grid columns",
            value: gridColumns,
            values: const [0, 3, 4, 5],
            name: (value) => value == 0 ? "auto" : "$value",
            onChanged: (value) => setState(() => gridColumns = value),
          ),
          _Choice<double>(
            label: "Grid cell aspect ratio",
            value: gridCellAspectRatio,
            values: const [0.5, 0.75, 1, 1.5],
            name: (value) => "$value",
            onChanged: (value) => setState(() => gridCellAspectRatio = value),
          ),
          SwitchListTile(
            title: const Text("Filters"),
            value: filters,
            onChanged: (value) => setState(() => filters = value),
          ),
          ListTile(
            title: Text("Output quality: $quality"),
            subtitle: Slider(
              value: quality.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (value) => setState(() => quality = value.round()),
            ),
          ),
          _Choice<int>(
            label: "Output max width",
            value: maxWidth,
            values: const [0, 1080, 2048, OutputOptions.safeMaxSide],
            name: (value) => value == 0 ? "off" : "$value",
            onChanged: (value) => setState(() => maxWidth = value),
          ),
          _Choice<int>(
            label: "Output max height",
            value: maxHeight,
            values: const [0, 1080, 2048, OutputOptions.safeMaxSide],
            name: (value) => value == 0 ? "off" : "$value",
            onChanged: (value) => setState(() => maxHeight = value),
          ),
          _Choice<ThemeChoice>(
            label: "Picker theme",
            value: theme,
            values: ThemeChoice.values,
            onChanged: (value) => setState(() => theme = value),
          ),
          SwitchListTile(
            title: const Text("Always dark theme"),
            subtitle: const Text("off follows the dark switch below"),
            value: alwaysDarkTheme,
            onChanged: (value) => setState(() => alwaysDarkTheme = value),
          ),
          _Choice<TextsChoice>(
            label: "Picker texts",
            value: texts,
            values: TextsChoice.values,
            onChanged: (value) => setState(() => texts = value),
          ),
          SwitchListTile(title: const Text("Cache"), value: cache, onChanged: (value) => setState(() => cache = value)),
          _Choice<int>(
            label: "Cache max size",
            value: cacheMb,
            values: const [50, 100, 500],
            name: (value) => "$value MB",
            onChanged: (value) => setState(() => cacheMb = value),
          ),
          SwitchListTile(title: const Text("Dark"), value: widget.dark, onChanged: widget.onDark),
          SwitchListTile(title: const Text("Right to left"), value: widget.rtl, onChanged: widget.onRtl),
          ListTile(
            title: Text("Text scale: ${widget.textScale.toStringAsFixed(1)}"),
            subtitle: Slider(value: widget.textScale, min: 0.8, max: 2, divisions: 12, onChanged: widget.onTextScale),
          ),
          _Results(items),
        ],
      ),
    );
  }
}

const PickerTheme customTheme = PickerTheme(
  background: Color(0xFF1B1530),
  surface: Color(0xFF2A2245),
  onSurface: Color(0xFFF3EEFF),
  onSurfaceMuted: Color(0xFFA79CC7),
  accent: Color(0xFFFF8A3D),
  onAccent: Color(0xFF1B1530),
  scrim: Color(0xFF000000),
);

const PickerTexts arabicTexts = PickerTexts(
  gallery: "المعرض",
  photo: "صورة",
  video: "فيديو",
  next: "التالي",
  add: "إضافة",
  done: "تم",
  close: "إغلاق",
  recent: "الأحدث",
  noImages: "لا توجد صور",
  noCamera: "لا توجد كاميرا",
  accessDenied: "اسمح بالوصول إلى صورك للمتابعة",
  cameraDenied: "اسمح بالوصول إلى الكاميرا للمتابعة",
  noMicrophone: "اسمح بالوصول إلى الميكروفون لتسجيل الصوت",
  openSettings: "فتح الإعدادات",
  manageAccess: "إدارة الوصول",
  maxReached: "يمكنك اختيار {max} عناصر كحد أقصى",
  videoNotEditable: "الفيديوهات يمكن ترتيبها فقط",
  notSupported: "هذه المنصة غير مدعومة بعد",
  crop: "قص",
  original: "الأصلي",
  select: "تحديد",
  cancel: "إلغاء",
  switchCamera: "تبديل الكاميرا",
  flash: "الفلاش",
  capture: "التقاط",
  processing: "جارٍ المعالجة",
  exportFailed: "تعذر حفظ الصور، حاول مرة أخرى",
  maxKept: "تم الاحتفاظ بأول {max} فقط",
  filesSkipped: "تعذر فتح بعض الملفات",
  filterNames: [
    "عادي",
    "دافئ",
    "بارد",
    "قديم",
    "جلامور",
    "درامي",
    "ناعم",
    "بني داكن",
    "تركوازي",
    "ساطع",
    "تباين",
    "باهت",
    "أحادي",
    "أسود",
  ],
  months: [
    "يناير",
    "فبراير",
    "مارس",
    "أبريل",
    "مايو",
    "يونيو",
    "يوليو",
    "أغسطس",
    "سبتمبر",
    "أكتوبر",
    "نوفمبر",
    "ديسمبر",
  ],
);

class _Choice<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;

  /// null uses the enum name.
  final String Function(T value)? name;
  final ValueChanged<T> onChanged;

  const _Choice({required this.label, required this.value, required this.values, required this.onChanged, this.name});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: SegmentedButton<T>(
        segments: [for (final v in values) ButtonSegment(value: v, label: Text(name?.call(v) ?? (v as Enum).name))],
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
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _Viewer(items: items, index: index),
            ),
          ),
          child: Stack(
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
          ),
        );
      },
    );
  }
}

/// the picked files full screen, swipe between them.
class _Viewer extends StatefulWidget {
  final List<PickedItem> items;
  final int index;

  const _Viewer({required this.items, required this.index});

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final PageController _pages = PageController(initialPage: widget.index);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: _pages,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.type == MediaType.video) return _VideoView(item.file.path);
          return InteractiveViewer(
            maxScale: 5,
            // on web the path is a blob url
            child: Center(child: kIsWeb ? Image.network(item.file.path) : Image.file(File(item.file.path))),
          );
        },
      ),
    );
  }
}

class _VideoView extends StatefulWidget {
  final String path;

  const _VideoView(this.path);

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  late final VideoPlayerController _player = kIsWeb
      ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
      : VideoPlayerController.file(File(widget.path));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _player.setLooping(true);
    _player.initialize().then(
      (_) {
        if (!mounted) return;
        setState(() {});
        _player.play();
      },
      onError: (_) {
        // windows and linux have no video player
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white));
    if (!_player.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: () => setState(() => _player.value.isPlaying ? _player.pause() : _player.play()),
      child: Center(
        child: AspectRatio(
          aspectRatio: _player.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_player),
              if (!_player.value.isPlaying) const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
            ],
          ),
        ),
      ),
    );
  }
}
