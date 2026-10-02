import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/models/media_item.dart';
import 'package:image_picker_plus/src/platform/platform.dart';
import 'package:image_picker_plus/src/widgets/loading_box.dart';
import 'package:video_player/video_player.dart';

/// loops muted, tap to play or pause.
class VideoPreview extends StatefulWidget {
  final MediaItem item;

  const VideoPreview({required this.item, super.key});

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
      await player.setVolume(0);
      await player.play();
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
    setState(() {});
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
        child: AspectRatio(aspectRatio: player.value.aspectRatio, child: VideoPlayer(player)),
      ),
    );
  }
}
