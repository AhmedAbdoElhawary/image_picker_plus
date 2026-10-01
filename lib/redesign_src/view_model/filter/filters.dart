import 'package:image_picker_plus/redesign_src/core/utils/string_manager.dart' show StringsManager;

class Filters {
  static List<Filter> get list {
    return <Filter>[
      Filter(StringsManager.noFilter, [
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.purple, [
        1, -0.2, 0, 0, 0, //
        0, 1, 0, -0.1, 0, //
        0, 1.2, 1, 0.1, 0, //
        0, 0, 1.7, 1, 0 //
      ]),
      Filter(StringsManager.yellow, [
        1, 0, 0, 0, 0, //
        -0.2, 1.0, 0.3, 0.1, 0, //
        -0.1, 0, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.cyan, [
        1, 0, 0, 1.9, -2.2, //
        0, 1, 0, 0.0, 0.3, //
        0, 0, 1, 0, 0.5, //
        0, 0, 0, 1, 0.2 //
      ]),
      Filter(StringsManager.bw, [
        0.3, 0.59, 0.11, 0, 0, //
        0.3, 0.59, 0.11, 0, 0, //
        0.3, 0.59, 0.11, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.oldTimes, [
        1, 0, 0, 0, 0, //
        -0.4, 1.3, -0.4, 0.2, -0.1, //
        0, 0, 1, 0, 0, //
        0, 0, 0, 1, 0 //
      ]),
      Filter(StringsManager.coldLife, [
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        -0.2, 0.2, 0.1, 0.4, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.sepium, [
        1.3, -0.3, 1.1, 0, 0, //
        0, 1.3, 0.2, 0, 0, //
        0, 0, 0.8, 0.2, 0, //
        0, 0, 0, 1, 0 //
      ]),
      Filter(StringsManager.milk, [
        0, 1.0, 0, 0, 0, //
        0, 1.0, 0, 0, 0, //
        0, 0.6, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.brightness, [
        1.2, 0, 0, 0, 0, //
        0, 1.2, 0, 0, 0, //
        0, 0, 1.2, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.contrast, [
        1.5, 0, 0, 0, -0.5, //
        0, 1.5, 0, 0, -0.5, //
        0, 0, 1.5, 0, -0.5, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.saturation, [
        1, 0, 0, 0, 0, //
        0, 1.2, 0, 0, 0, //
        0, 0, 1.5, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.warmth, [
        1.3, 0, 0, 0, 0, //
        0, 1.0, 0, 0, 0, //
        0, 0, 0.8, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.vignette, [
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        -0.5, -0.5, -0.5, 1, 0.5, //
      ]),
      Filter(StringsManager.sharpen, [
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        -1, -1, -1, 5, -1, //
      ]),
      Filter(StringsManager.bwRedChannel, [
        1, 0, 0, 0, 0, //
        0, 0, 0, 0, 0, //
        0, 0, 0, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.sepiaTone, [
        1.1, 0.3, 0.2, 0, 0, //
        0.2, 1, 0.1, 0, 0, //
        0.1, 0.2, 0.7, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.haze, [
        0.9, 0.1, 0.1, 0, 0.1, //
        0.1, 0.9, 0.1, 0, 0.1, //
        0.1, 0.1, 0.9, 0, 0.1, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.crimson, [
        1.2, 0, 0, 0, 0, //
        0, 0.8, 0.2, 0, 0, //
        0, 0, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.tealOrange, [
        1.2, 0.1, -0.1, 0, 0, //
        -0.1, 1, 0.1, 0.2, 0, //
        -0.1, 0, 1.2, -0.1, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.darken, [
        0.8, 0, 0, 0, 0, //
        0, 0.8, 0, 0, 0, //
        0, 0, 0.8, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.brighten, [
        1, 0, 0, 0, 0.2, //
        0, 1, 0, 0, 0.2, //
        0, 0, 1, 0, 0.2, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.popArt, [
        1.2, -0.1, 0, 0, 0, //
        -0.1, 1.1, -0.1, 0, 0, //
        0, -0.1, 1.2, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.bwHighContrast, [
        0.3, 0.7, 0.3, 0, 0, //
        0.3, 0.7, 0.3, 0, 0, //
        0.3, 0.7, 0.3, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.cool, [
        1, 0, 0, -0.1, //
        0, 0, 1, 0, //
        0.1, 0, 0, 0, //
        1, -0.2, 0, 0, //
        0, 0, 1, 0, //
      ]),
      Filter(StringsManager.vintage, [
        0.9, 0.05, 0.15, 0, 0, //
        0.05, 0.9, 0.15, 0, 0, //
        0.15, 0.15, 0.8, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.glamour, [
        1.2, -0.1, 0.2, 0, 0, //
        0.1, 1.1, 0.1, 0, 0, //
        0.1, 0.2, 1.1, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.lomo, [
        1.5, -0.5, 0.1, 0, 0, //
        0.1, 1.4, 0.1, 0, 0, //
        0.1, 0.2, 1.4, 0, 0, //
        0, 0, 0, 1, -0.1, //
      ]),
      Filter(StringsManager.dramatic, [
        1.5, 0.5, -0.3, 0, 0, //
        0.3, 1.3, 0.1, 0, 0, //
        0.2, 0.3, 1.2, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.soft, [
        1.2, 0.2, 0.2, 0, 0, //
        0.2, 1.1, 0.2, 0, 0, //
        0.2, 0.2, 1.2, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      Filter(StringsManager.rioDeJaneiro, [
        1.1, 0.1, 0, 0, //
        0, -0.1, 1.1, 0.1, //
        0, 0, 0, 0.1, //
        1, 0, 0, 0, //
        0, 0, 1, 0.1,
      ]),
      Filter(StringsManager.tokyo, [
        1.2, 0, 0, 0, //
        0, 0, 1.2, -0.2, //
        0, 0, 0, -0.2, //
        1.2, 0, 0, 0, //
        0, 0, 1, 0.1, //
      ])
    ];
  }
}

class Filter {
  String filterName;
  List<double> matrix;

  Filter(this.filterName, this.matrix);
}
