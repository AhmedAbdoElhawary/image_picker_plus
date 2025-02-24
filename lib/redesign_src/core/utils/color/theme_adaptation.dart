class ThemeAdaptation {
  static final ThemeAdaptation _instance = ThemeAdaptation._internal();
  factory ThemeAdaptation() => _instance;
  ThemeAdaptation._internal();

  bool? _isLight;

  bool get isLight => _isLight!;

  set initializeScreenSize(bool value) {
    _isLight = value;
  }
}
