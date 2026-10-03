import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/platform/video_handle.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';

/// loops muted, tap to play or pause.
class VideoPreview extends StatefulWidget {
  final MediaItem item;

  /// false on the edit page, it starts paused with sound.
  final bool autoplay;

  const VideoPreview({required this.item, this.autoplay = true, super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoHandle? _player;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_player == null && !_failed) _load();
  }

  Future<void> _load() async {
    final path =
        widget.item.path ?? (await PickerScope.of(context).services.gallery!.file(widget.item))?.path;
    if (!mounted) return;
    final player = path == null ? null : videoPlayer(path);
    if (player == null) {
      setState(() => _failed = true);
      return;
    }
    _player = player;
    try {
      await player.initialize(muted: widget.autoplay);
      if (widget.autoplay) await player.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _toggle() {
    final player = _player;
    if (player == null || !player.isInitialized) return;
    player.isPlaying ? player.pause() : player.play();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final name = widget.item.name;
    final texts = PickerScope.of(context).texts;
    if (_failed) {
      // web, windows and linux have no player, the name tells the videos apart
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code_off_rounded, color: theme.onSurfaceMuted),
            if (name != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: Text(
                  texts.videoPreviewNotSupported,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.onSurfaceMuted),
                ),
              ),
          ],
        ),
      );
    }
    final player = _player;
    if (player == null || !player.isInitialized) return const LoadingBox();
    return GestureDetector(
      onTap: _toggle,
      child: Center(
        child: AspectRatio(
          aspectRatio: player.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              player.view(),
              _PlayIcon(player: player),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayIcon extends StatelessWidget {
  final VideoHandle player;

  const _PlayIcon({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return Selector<bool>(
      listenable: player,
      select: () => player.isPlaying,
      builder: (context, playing, child) => AnimatedOpacity(
        opacity: playing ? 0 : 1,
        duration: PickerDurations.of(context).short,
        child: child,
      ),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.background.withValues(alpha: 0.6), shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(12),
            child: Icon(Icons.play_arrow_rounded, color: theme.onSurface, size: 36),
          ),
        ),
      ),
    );
  }
}
