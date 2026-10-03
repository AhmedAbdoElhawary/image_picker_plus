// cross_file isn't a direct dependency: its 0.4.0 is a different api, without
// `XFile(path)` or `fromData`, and camera and file_selector still hand out the 0.3 one.
export 'package:file_selector/file_selector.dart' show XFile;
