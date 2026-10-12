import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final ValueNotifier<bool> dark = ValueNotifier(false);
  final ValueNotifier<bool> rtl = ValueNotifier(false);
  final ValueNotifier<double> textScale = ValueNotifier(1);

  @override
  void dispose() {
    for (final notifier in [dark, rtl, textScale]) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: dark,
      // same demo instance, so the dark switch doesn't build it again
      child: Demo(dark: dark, rtl: rtl, textScale: textScale),
      builder: (context, isDark, home) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(colorSchemeSeed: Colors.blue),
        darkTheme: ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.dark),
        builder: (context, child) => ListenableBuilder(
          listenable: Listenable.merge([rtl, textScale]),
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale.value)),
            child: Directionality(
              textDirection: rtl.value ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
          ),
        ),
        home: home,
      ),
    );
  }
}

class Demo extends StatefulWidget {
  final ValueNotifier<bool> dark;
  final ValueNotifier<bool> rtl;
  final ValueNotifier<double> textScale;

  const Demo({required this.dark, required this.rtl, required this.textScale, super.key});

  @override
  State<Demo> createState() => _DemoState();
}

enum ThemeChoice { app, custom }

enum TextsChoice { english, arabic, app }

enum FiltersChoice { off, shipped, custom }

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

  final ValueNotifier<PickerSource> source = ValueNotifier(PickerSource.both);
  final ValueNotifier<MediaType> mediaType = ValueNotifier(MediaType.all);
  final ValueNotifier<int> maxSelection = ValueNotifier(10);
  final ValueNotifier<Set<CropRatio>> ratios = ValueNotifier(allRatios.toSet());
  final ValueNotifier<bool> showPreview = ValueNotifier(true);
  final ValueNotifier<bool> resizePreview = ValueNotifier(true);

  /// 0 follows the screen width.
  final ValueNotifier<int> gridColumns = ValueNotifier(0);
  final ValueNotifier<double> gridCellAspectRatio = ValueNotifier(1);
  final ValueNotifier<FiltersChoice> filters = ValueNotifier(FiltersChoice.shipped);
  final ValueNotifier<bool> adjustments = ValueNotifier(true);
  final ValueNotifier<bool> png = ValueNotifier(false);
  final ValueNotifier<int> quality = ValueNotifier(90);

  /// 0 keeps the image size.
  final ValueNotifier<int> maxWidth = ValueNotifier(0);
  final ValueNotifier<int> maxHeight = ValueNotifier(0);

  /// 0 has no limit.
  final ValueNotifier<int> maxKb = ValueNotifier(0);
  final ValueNotifier<ThemeChoice> theme = ValueNotifier(ThemeChoice.app);
  final ValueNotifier<bool> alwaysDarkTheme = ValueNotifier(true);
  final ValueNotifier<TextsChoice> texts = ValueNotifier(TextsChoice.english);
  final ValueNotifier<bool> cache = ValueNotifier(false);

  final ValueNotifier<bool> text = ValueNotifier(true);
  final ValueNotifier<bool> emojis = ValueNotifier(true);
  final ValueNotifier<bool> drawing = ValueNotifier(true);

  /// grid on at start.
  final ValueNotifier<bool> cameraGrid = ValueNotifier(false);

  /// an id card frame over the camera.
  final ValueNotifier<bool> cardFrame = ValueNotifier(false);
  final ValueNotifier<int> cacheMb = ValueNotifier(100);
  final ValueNotifier<List<PickedItem>> items = ValueNotifier(const []);

  /// web has no temp dir, the saved pick stays in memory there.
  String? _savedOnWeb;
  File get _savedFile => File("${Directory.systemTemp.path}/last_pick.json");
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    for (final notifier in <ChangeNotifier>[
      source,
      mediaType,
      maxSelection,
      ratios,
      showPreview,
      resizePreview,
      gridColumns,
      gridCellAspectRatio,
      filters,
      adjustments,
      png,
      quality,
      maxWidth,
      maxHeight,
      maxKb,
      theme,
      alwaysDarkTheme,
      texts,
      cache,
      text,
      emojis,
      drawing,
      cameraGrid,
      cardFrame,
      cacheMb,
      items,
    ]) {
      notifier.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  /// [selected] opens with an earlier pick, its crops and filters.
  Future<void> _pick({List<PickedItem>? selected}) async {
    final picked = await ImagePickerPlus.pick(
      context,
      selected: selected,
      settings: PickerSettings(
        source: source.value,
        mediaType: mediaType.value,
        maxSelection: maxSelection.value,
        // the first one is where the crop starts, so keep the list order
        cropRatios: [
          for (final ratio in allRatios)
            if (ratios.value.contains(ratio)) ratio,
        ],
        showPreview: showPreview.value,
        resizePreview: resizePreview.value,
        gridColumns: gridColumns.value == 0 ? null : gridColumns.value,
        gridCellAspectRatio: gridCellAspectRatio.value,
        filters: switch (filters.value) {
          FiltersChoice.off => const [],
          FiltersChoice.shipped => PickerFilter.all,
          FiltersChoice.custom => customFilters,
        },
        adjustments: adjustments.value,
        output: OutputOptions(
          format: png.value ? OutputFormat.png : OutputFormat.jpeg,
          quality: quality.value,
          maxWidth: maxWidth.value == 0 ? null : maxWidth.value,
          maxHeight: maxHeight.value == 0 ? null : maxHeight.value,
          maxBytes: maxKb.value == 0 ? null : maxKb.value * 1024,
        ),
        theme: theme.value == ThemeChoice.custom ? customTheme : null,
        alwaysDarkTheme: alwaysDarkTheme.value,
        texts: switch (texts.value) {
          TextsChoice.english => const PickerTexts(),
          TextsChoice.arabic => const ArabicTexts(),
          TextsChoice.app => PickerTexts.of(context),
        },
        cache: PickerCache(enabled: cache.value, maxBytes: cacheMb.value * 1024 * 1024),
        markup: MarkupOptions(text: text.value, emojis: emojis.value, drawing: drawing.value),
        camera: CameraOptions(gridOn: cameraGrid.value, overlay: cardFrame.value ? _cardFrame : null),
      ),
    );
    if (picked == null) return;
    items.value = picked;
    // the results grid only has its height after this frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _save() async {
    final items = this.items.value;
    try {
      final json = jsonEncode([for (final item in items) item.toMap()]);
      kIsWeb ? _savedOnWeb = json : await _savedFile.writeAsString(json);
      if (kIsWeb) return _tell("Saved ${items.length} items for load, web has no gallery");
      final allowed = await Gal.hasAccess() || await Gal.requestAccess();
      if (!allowed) return _tell("Allow adding to photos to save");
      for (final item in items) {
        item.type == MediaType.video
            ? await Gal.putVideo(item.file.path)
            : await Gal.putImage(item.file.path);
      }
      _tell("Saved ${items.length} items to the gallery");
    } catch (error) {
      _tell("Couldn't save: $error");
    }
  }

  Future<void> _load() async {
    try {
      final json = kIsWeb ? _savedOnWeb : (_savedFile.existsSync() ? await _savedFile.readAsString() : null);
      if (json == null) return _tell("Nothing saved yet");
      items.value = [for (final map in jsonDecode(json) as List) PickedItem.fromMap(map)];
      _tell("Loaded ${items.value.length} items, change photos opens them with their edits");
    } catch (error) {
      _tell("Couldn't load: $error");
    }
  }

  // without it both buttons look like they did nothing
  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        controller: _scroll,
        padding: const EdgeInsetsDirectional.only(bottom: 96),
        children: [
          _Choice<PickerSource>(label: "Source", notifier: source, values: PickerSource.values),
          _Choice<MediaType>(label: "Media", notifier: mediaType, values: MediaType.values),
          _Slider(label: "Max selection", notifier: maxSelection, min: 1, max: 20),
          ValueListenableBuilder<Set<CropRatio>>(
            valueListenable: ratios,
            builder: (context, selectedRatios, _) => ListTile(
              title: Text("Crop ratios${selectedRatios.isEmpty ? ": off" : ""}"),
              subtitle: Wrap(
                spacing: 8,
                children: [
                  for (final ratio in allRatios)
                    FilterChip(
                      label: Text("$ratio"),
                      selected: selectedRatios.contains(ratio),
                      onSelected: (selected) => ratios.value = selected
                          ? {...selectedRatios, ratio}
                          : ({...selectedRatios}..remove(ratio)),
                    ),
                ],
              ),
            ),
          ),
          _Switch(title: "Show preview", notifier: showPreview),
          _Switch(
            title: "Resize preview",
            subtitle: "off decodes the preview at 1080 pixels",
            notifier: resizePreview,
          ),
          _Choice<int>(
            label: "Grid columns",
            notifier: gridColumns,
            values: const [0, 3, 4, 5],
            name: (value) => value == 0 ? "auto" : "$value",
          ),
          _Choice<double>(
            label: "Grid cell aspect ratio",
            notifier: gridCellAspectRatio,
            values: const [0.5, 0.75, 1, 1.5],
            name: (value) => "$value",
          ),
          _Choice<FiltersChoice>(label: "Filters", notifier: filters, values: FiltersChoice.values),
          _Switch(title: "Adjustments", notifier: adjustments),
          _Switch(title: "PNG output", subtitle: "keeps transparency, quality does nothing", notifier: png),
          _Slider(label: "Output quality", notifier: quality, min: 1, max: 100),
          _Choice<int>(
            label: "Output max width",
            notifier: maxWidth,
            values: const [0, 1080, 2048, OutputOptions.safeMaxSide],
            name: (value) => value == 0 ? "off" : "$value",
          ),
          _Choice<int>(
            label: "Output max height",
            notifier: maxHeight,
            values: const [0, 1080, 2048, OutputOptions.safeMaxSide],
            name: (value) => value == 0 ? "off" : "$value",
          ),
          _Choice<int>(
            label: "Output max size",
            notifier: maxKb,
            values: const [0, 500, 1024, 2048],
            name: (value) => value == 0 ? "off" : "$value KB",
          ),
          _Choice<ThemeChoice>(label: "Picker theme", notifier: theme, values: ThemeChoice.values),
          _Switch(
            title: "Always dark theme",
            subtitle: "off follows the dark switch below",
            notifier: alwaysDarkTheme,
          ),
          _Choice<TextsChoice>(label: "Picker texts", notifier: texts, values: TextsChoice.values),
          _Switch(title: "Cache", notifier: cache),
          _Choice<int>(
            label: "Cache max size",
            notifier: cacheMb,
            values: const [50, 100, 500],
            name: (value) => "$value MB",
          ),
          _Switch(title: "Text", notifier: text),
          _Switch(title: "Emojis", notifier: emojis),
          _Switch(title: "Drawing", notifier: drawing),
          _Switch(title: "Camera grid on at start", notifier: cameraGrid),
          _Switch(title: "Card frame over the camera", notifier: cardFrame),
          _Switch(title: "Dark", notifier: widget.dark),
          _Switch(title: "Right to left", notifier: widget.rtl),
          ValueListenableBuilder<double>(
            valueListenable: widget.textScale,
            builder: (context, value, _) => ListTile(
              title: Text("Text scale: ${value.toStringAsFixed(1)}"),
              subtitle: Slider(
                value: value,
                min: 0.8,
                max: 2,
                divisions: 12,
                onChanged: (value) => widget.textScale.value = value,
              ),
            ),
          ),
          ValueListenableBuilder<List<PickedItem>>(
            valueListenable: items,
            builder: (context, items, _) => Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (items.isNotEmpty)
                      OutlinedButton(
                        onPressed: () => _pick(selected: items),
                        child: const Text("Change photos"),
                      ),
                    if (items.isNotEmpty) OutlinedButton(onPressed: _save, child: const Text("Save")),
                    OutlinedButton(onPressed: _load, child: const Text("Load")),
                  ],
                ),
                _Results(items),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _cardFrame(BuildContext context, Size size) => Center(
  child: Container(
    width: size.width * 0.85,
    height: size.width * 0.85 / 1.586,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);

const PickerTheme customTheme = PickerTheme(
  background: Color(0xFF1B1530),
  surface: Color(0xFF2A2245),
  onSurface: Color(0xFFF3EEFF),
  onSurfaceMuted: Color(0xFFA79CC7),
  accent: Color(0xFFFF8A3D),
  onAccent: Color(0xFF1B1530),
  scrim: Color(0xFF000000),
);

/// three made up looks, to show a strip with only the app's own filters.
const List<PickerFilter> customFilters = [
  PickerFilter(
    name: "Sunset",
    matrix: [
      1.2, 0.1, 0, 0, 10, //
      0, 1, 0, 0, 0, //
      0, 0, 0.8, 0, -10, //
      0, 0, 0, 1, 0, //
    ],
  ),
  PickerFilter(
    name: "Ocean",
    matrix: [
      0.8, 0, 0, 0, 0, //
      0, 1, 0.1, 0, 0, //
      0, 0.1, 1.2, 0, 15, //
      0, 0, 0, 1, 0, //
    ],
  ),
  PickerFilter(
    name: "Ink",
    matrix: [
      0.4, 0.8, 0.2, 0, -30, //
      0.4, 0.8, 0.2, 0, -30, //
      0.4, 0.8, 0.2, 0, -30, //
      0, 0, 0, 1, 0, //
    ],
  ),
];

class _Choice<T> extends StatelessWidget {
  final String label;
  final ValueNotifier<T> notifier;
  final List<T> values;

  /// null uses the enum name.
  final String Function(T value)? name;

  const _Choice({required this.label, required this.notifier, required this.values, this.name});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: ValueListenableBuilder<T>(
        valueListenable: notifier,
        builder: (context, value, _) => SegmentedButton<T>(
          segments: [
            for (final v in values) ButtonSegment(value: v, label: Text(name?.call(v) ?? (v as Enum).name)),
          ],
          selected: {value},
          onSelectionChanged: (selected) => notifier.value = selected.first,
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ValueNotifier<bool> notifier;

  const _Switch({required this.title, required this.notifier, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) => SwitchListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        value: value,
        onChanged: (value) => notifier.value = value,
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final ValueNotifier<int> notifier;
  final int min;
  final int max;

  const _Slider({required this.label, required this.notifier, required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, value, _) => ListTile(
        title: Text("$label: $value"),
        subtitle: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (value) => notifier.value = value.round(),
        ),
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
                  "${index + 1} · ${item.width}x${item.height}${item.edited ? " · edited" : ""}"
                  "${item.overLimit ? " · over" : ""}",
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

  /// play and pause are async, the value they set is not, so the icon can be drawn right away.
  void _toggle() {
    _player.value.isPlaying ? _player.pause() : _player.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white));
    if (!_player.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: _toggle,
      child: Center(
        child: AspectRatio(
          aspectRatio: _player.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_player),
              if (!_player.value.isPlaying)
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
            ],
          ),
        ),
      ),
    );
  }
}
