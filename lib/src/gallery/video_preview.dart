import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _player;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_player == null && !_failed) _load();
  }

  Future<void> _load() async {
    final path = widget.item.path ?? (await PickerScope.of(context).services.gallery!.file(widget.item))?.path;
    if (!mounted) return;
    if (path == null) {
      setState(() => _failed = true);
      return;
    }
    final player = videoPlayer(path);
    _player = player;
    try {
      await player.initialize();
      await player.setLooping(true);
      if (widget.autoplay) {
        await player.setVolume(0);
        await player.play();
      }
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
    if (player == null || !player.value.isInitialized) return;
    player.value.isPlaying ? player.pause() : player.play();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    final name = widget.item.name;
    if (_failed) {
      // windows and linux have no player, the name tells the videos apart
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: theme.onSurfaceMuted),
            if (name != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.onSurfaceMuted),
                ),
              ),
          ],
        ),
      );
    }
    final player = _player;
    if (player == null || !player.value.isInitialized) return const LoadingBox();
    return GestureDetector(
      onTap: _toggle,
      child: Center(
        child: AspectRatio(
          aspectRatio: player.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(player),
              _PlayIcon(player: player),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayIcon extends StatelessWidget {
  final VideoPlayerController player;

  const _PlayIcon({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return Selector<bool>(
      listenable: player,
      select: () => player.value.isPlaying,
      builder: (context, playing, child) =>
          AnimatedOpacity(opacity: playing ? 0 : 1, duration: PickerDurations.of(context).short, child: child),
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
