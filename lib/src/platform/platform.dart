// dart:io, dart:isolate and photo_manager stay out of web builds, and out of pub.dev's web check
export 'platform_web.dart' if (dart.library.io) 'platform_io.dart';
