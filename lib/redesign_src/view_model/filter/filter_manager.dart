import 'package:image/image.dart' as img;

import 'apply_filter_params.dart' show ApplyFilterParams;

class FilterManager {
  static img.Image applyFilter(ApplyFilterParams applyFilterParams) {
    for (int y = 0; y < applyFilterParams.img.height; y++) {
      for (int x = 0; x < applyFilterParams.img.width; x++) {
        final img.Pixel pixel = applyFilterParams.img.getPixel(x, y);

        final num alpha = pixel.a;
        final num red = pixel.r;
        final num green = pixel.g;
        final num blue = pixel.b;

        final newColor = _multiplyByColorFilter([red, green, blue, alpha], applyFilterParams.colorMatrix);

        final color = img.ColorRgba8(newColor[0], newColor[1], newColor[2], newColor[3]);
        applyFilterParams.img.setPixel(x, y, color);
      }
    }

    return applyFilterParams.img;
  }

  static List<int> _multiplyByColorFilter(List<num> color, List<double> matrix) {
    final r = (color[0] * matrix[0] +
            color[1] * matrix[1] +
            color[2] * matrix[2] +
            color[3] * matrix[3] +
            matrix[4])
        .clamp(0, 255)
        .toInt();
    final g = (color[0] * matrix[5] +
            color[1] * matrix[6] +
            color[2] * matrix[7] +
            color[3] * matrix[8] +
            matrix[9])
        .clamp(0, 255)
        .toInt();
    final b = (color[0] * matrix[10] +
            color[1] * matrix[11] +
            color[2] * matrix[12] +
            color[3] * matrix[13] +
            matrix[14])
        .clamp(0, 255)
        .toInt();
    final a = (color[0] * matrix[15] +
            color[1] * matrix[16] +
            color[2] * matrix[17] +
            color[3] * matrix[18] +
            matrix[19])
        .clamp(0, 255)
        .toInt();

    return [r, g, b, a];
  }
}
