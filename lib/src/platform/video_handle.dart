import 'package:flutter/widgets.dart';

/// the player behind the video preview. web has none, video_player's library
/// imports dart:io and that keeps the whole package off wasm.
abstract class VideoHandle implements Listenable {
  bool get isInitialized;

  bool get isPlaying;

  double get aspectRatio;

  /// loops, and silent when [muted]. it stays paused until [play].
  Future<void> initialize({required bool muted});

  Future<void> play();

  Future<void> pause();

  Widget view();

  void dispose();
}
