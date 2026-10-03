// dart:io, dart:isolate, photo_manager and video_player stay out of web builds, and out of pub.dev's web check
export 'platform_web.dart' if (dart.library.io) 'platform_io.dart';
