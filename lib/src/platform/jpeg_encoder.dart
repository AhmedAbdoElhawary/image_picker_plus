import 'dart:math';
import 'dart:typed_data';

/// baseline jpeg, 4:2:0 with the standard tables. each strip is its own restart interval,
/// so strips encode apart and join as they are.
/// the image package's encoder reads a pixel object per pixel and writes bit by bit, this is a few times faster.
Uint8List encodeJpegStrip(Uint8List rgba, int width, int height, int quality) =>
    _Strip(rgba, width, height, quality).encode();

/// about 4 mb of pixels, in whole mcu rows so only the last strip has a partial one,
/// and few enough mcus for a restart interval.
int jpegStripRows(int width) {
  final mcuColumns = (width + 15) >> 4;
  return max(1, min((1 << 16) ~/ width, 65535 ~/ mcuColumns)) << 4;
}

/// the headers, then the strips with a restart marker between each.
Uint8List joinJpeg(List<Uint8List> strips, int width, int height, int quality, int stripRows) {
  final luma = _quant(_lumaBase, quality);
  final chroma = _quant(_chromaBase, quality);
  final bytes = BytesBuilder(copy: false)
    ..add([0xff, 0xd8])
    ..add([0xff, 0xe0, 0, 16, 0x4a, 0x46, 0x49, 0x46, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0])
    ..add([0xff, 0xdb, 0, 132, 0])
    ..add(_zigzagged(luma))
    ..addByte(1)
    ..add(_zigzagged(chroma))
    ..add([0xff, 0xc0, 0, 17, 8, height >> 8, height & 0xff, width >> 8, width & 0xff])
    ..add([3, 1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1]);
  for (final (id, counts, values) in [
    (0x00, _dcLumaCounts, _dcValues),
    (0x10, _acLumaCounts, _acLumaValues),
    (0x01, _dcChromaCounts, _dcValues),
    (0x11, _acChromaCounts, _acChromaValues),
  ]) {
    final length = 3 + counts.length + values.length;
    bytes
      ..add([0xff, 0xc4, length >> 8, length & 0xff, id])
      ..add(counts)
      ..add(values);
  }
  if (strips.length > 1) {
    final interval = (stripRows >> 4) * ((width + 15) >> 4);
    bytes.add([0xff, 0xdd, 0, 4, interval >> 8, interval & 0xff]);
  }
  bytes.add([0xff, 0xda, 0, 12, 3, 1, 0, 2, 0x11, 3, 0x11, 0, 0x3f, 0]);
  for (var i = 0; i < strips.length; i++) {
    if (i > 0) bytes.add([0xff, 0xd0 + (i - 1) % 8]);
    bytes.add(strips[i]);
  }
  bytes.add([0xff, 0xd9]);
  return bytes.takeBytes();
}

class _Strip {
  final Uint8List rgba;
  final int width;
  final int height;
  final Float32List lumaScale;
  final Float32List chromaScale;
  final Int32List coefficients = Int32List(64);
  Uint8List out;
  int length = 0;
  int bits = 0;
  int count = 0;

  _Strip(this.rgba, this.width, this.height, int quality)
    : lumaScale = _scale(_quant(_lumaBase, quality)),
      chromaScale = _scale(_quant(_chromaBase, quality)),
      out = Uint8List(max(1024, width * height ~/ 2));

  Uint8List encode() {
    final luma = List.generate(4, (_) => Float32List(64));
    final blue = Float32List(64);
    final red = Float32List(64);
    final columns = Int32List(16);
    var dcLuma = 0;
    var dcBlue = 0;
    var dcRed = 0;
    for (var top = 0; top < height; top += 16) {
      for (var left = 0; left < width; left += 16) {
        // the edge pixel repeats past the right and bottom
        for (var column = 0; column < 16; column++) {
          columns[column] = min(left + column, width - 1);
        }
        blue.fillRange(0, 64, 0);
        red.fillRange(0, 64, 0);
        for (var row = 0; row < 16; row++) {
          final start = min(top + row, height - 1) * width;
          final half = (row >> 3) << 1;
          final lumaRow = (row & 7) << 3;
          final chromaRow = (row >> 1) << 3;
          for (var column = 0; column < 16; column++) {
            final i = (start + columns[column]) << 2;
            // premultiplied, so over white it's the color plus what alpha leaves
            final rest = 255 - rgba[i + 3];
            final r = rgba[i] + rest;
            final g = rgba[i + 1] + rest;
            final b = rgba[i + 2] + rest;
            luma[half | (column >> 3)][lumaRow | (column & 7)] = 0.299 * r + 0.587 * g + 0.114 * b - 128;
            // a quarter each, the 4 pixels of a 2x2 add up to the average
            final c = chromaRow | (column >> 1);
            blue[c] += -0.042184 * r - 0.082816 * g + 0.125 * b;
            red[c] += 0.125 * r - 0.104672 * g - 0.020328 * b;
          }
        }
        for (final block in luma) {
          dcLuma = _block(block, lumaScale, dcLuma, _dcLuma, _acLuma);
        }
        dcBlue = _block(blue, chromaScale, dcBlue, _dcChroma, _acChroma);
        dcRed = _block(red, chromaScale, dcRed, _dcChroma, _acChroma);
      }
    }
    // the restart marker and the end marker need a whole byte, the rest is filled with 1s
    if (count > 0) _write((1 << (8 - count)) - 1, 8 - count);
    return Uint8List.sublistView(out, 0, length);
  }

  int _block(Float32List data, Float32List scale, int dc, _Huffman dcTable, _Huffman acTable) {
    _dct(data);
    final zz = coefficients;
    for (var k = 0; k < 64; k++) {
      final v = data[k] * scale[k];
      zz[_zigzag[k]] = v > 0 ? (v + 0.5).toInt() : (v - 0.5).toInt();
    }
    final diff = zz[0] - dc;
    final dcSize = (diff < 0 ? -diff : diff).bitLength;
    _write(dcTable.codes[dcSize], dcTable.lengths[dcSize]);
    if (dcSize > 0) _write(diff < 0 ? diff + (1 << dcSize) - 1 : diff, dcSize);

    var last = 63;
    while (last > 0 && zz[last] == 0) {
      last--;
    }
    var zeros = 0;
    for (var k = 1; k <= last; k++) {
      final v = zz[k];
      if (v == 0) {
        zeros++;
        continue;
      }
      while (zeros >= 16) {
        _write(acTable.codes[0xf0], acTable.lengths[0xf0]);
        zeros -= 16;
      }
      final size = (v < 0 ? -v : v).bitLength;
      final symbol = (zeros << 4) | size;
      _write(acTable.codes[symbol], acTable.lengths[symbol]);
      _write(v < 0 ? v + (1 << size) - 1 : v, size);
      zeros = 0;
    }
    if (last < 63) _write(acTable.codes[0], acTable.lengths[0]);
    return zz[0];
  }

  void _write(int value, int size) {
    bits = (bits << size) | value;
    count += size;
    while (count >= 8) {
      count -= 8;
      final byte = (bits >> count) & 0xff;
      if (length + 2 > out.length) out = (Uint8List(out.length * 2)..setAll(0, out));
      out[length++] = byte;
      // a 0xff in the data would read as a marker
      if (byte == 0xff) out[length++] = 0;
    }
    bits &= (1 << count) - 1;
  }

  /// the aan float dct, scaled per coefficient after, in place.
  static void _dct(Float32List data) {
    for (var pass = 0; pass < 2; pass++) {
      // rows, then columns
      final step = pass == 0 ? 1 : 8;
      final next = pass == 0 ? 8 : 1;
      for (var i = 0, o = 0; i < 8; i++, o += next) {
        final d0 = data[o];
        final d1 = data[o + step];
        final d2 = data[o + 2 * step];
        final d3 = data[o + 3 * step];
        final d4 = data[o + 4 * step];
        final d5 = data[o + 5 * step];
        final d6 = data[o + 6 * step];
        final d7 = data[o + 7 * step];

        final tmp0 = d0 + d7;
        final tmp7 = d0 - d7;
        final tmp1 = d1 + d6;
        final tmp6 = d1 - d6;
        final tmp2 = d2 + d5;
        final tmp5 = d2 - d5;
        final tmp3 = d3 + d4;
        final tmp4 = d3 - d4;

        final tmp10 = tmp0 + tmp3;
        final tmp13 = tmp0 - tmp3;
        final tmp11 = tmp1 + tmp2;
        final tmp12 = tmp1 - tmp2;
        data[o] = tmp10 + tmp11;
        data[o + 4 * step] = tmp10 - tmp11;
        final z1 = (tmp12 + tmp13) * 0.707106781;
        data[o + 2 * step] = tmp13 + z1;
        data[o + 6 * step] = tmp13 - z1;

        final odd10 = tmp4 + tmp5;
        final odd11 = tmp5 + tmp6;
        final odd12 = tmp6 + tmp7;
        final z5 = (odd10 - odd12) * 0.382683433;
        final z2 = 0.541196100 * odd10 + z5;
        final z4 = 1.306562965 * odd12 + z5;
        final z3 = odd11 * 0.707106781;
        final z11 = tmp7 + z3;
        final z13 = tmp7 - z3;
        data[o + 5 * step] = z13 + z2;
        data[o + 3 * step] = z13 - z2;
        data[o + step] = z11 + z4;
        data[o + 7 * step] = z11 - z4;
      }
    }
  }
}

class _Huffman {
  final Int32List codes = Int32List(256);
  final Uint8List lengths = Uint8List(256);

  _Huffman(List<int> counts, List<int> values) {
    var code = 0;
    var index = 0;
    for (var length = 1; length <= 16; length++) {
      for (var i = 0; i < counts[length - 1]; i++) {
        codes[values[index]] = code++;
        lengths[values[index++]] = length;
      }
      code <<= 1;
    }
  }
}

/// natural order, the same scaling as libjpeg.
Uint8List _quant(List<int> base, int quality) {
  final factor = quality < 50 ? 5000 ~/ quality : 200 - quality * 2;
  return Uint8List.fromList([for (final v in base) ((v * factor + 50) ~/ 100).clamp(1, 255)]);
}

Uint8List _zigzagged(Uint8List natural) {
  final out = Uint8List(64);
  for (var k = 0; k < 64; k++) {
    out[_zigzag[k]] = natural[k];
  }
  return out;
}

/// the aan dct leaves each coefficient scaled, this undoes it together with the quantization.
Float32List _scale(Uint8List quant) {
  const aan = [1.0, 1.387039845, 1.306562965, 1.175875602, 1.0, 0.785694958, 0.541196100, 0.275899379];
  return Float32List.fromList([for (var k = 0; k < 64; k++) 1 / (quant[k] * aan[k >> 3] * aan[k & 7] * 8)]);
}

final _Huffman _dcLuma = _Huffman(_dcLumaCounts, _dcValues);
final _Huffman _acLuma = _Huffman(_acLumaCounts, _acLumaValues);
final _Huffman _dcChroma = _Huffman(_dcChromaCounts, _dcValues);
final _Huffman _acChroma = _Huffman(_acChromaCounts, _acChromaValues);

/// natural index to its zigzag position.
const List<int> _zigzag = [
  0, 1, 5, 6, 14, 15, 27, 28, 2, 4, 7, 13, 16, 26, 29, 42, //
  3, 8, 12, 17, 25, 30, 41, 43, 9, 11, 18, 24, 31, 40, 44, 53,
  10, 19, 23, 32, 39, 45, 52, 54, 20, 22, 33, 38, 46, 51, 55, 60,
  21, 34, 37, 47, 50, 56, 59, 61, 35, 36, 48, 49, 57, 58, 62, 63,
];

const List<int> _lumaBase = [
  16, 11, 10, 16, 24, 40, 51, 61, 12, 12, 14, 19, 26, 58, 60, 55, //
  14, 13, 16, 24, 40, 57, 69, 56, 14, 17, 22, 29, 51, 87, 80, 62,
  18, 22, 37, 56, 68, 109, 103, 77, 24, 35, 55, 64, 81, 104, 113, 92,
  49, 64, 78, 87, 103, 121, 120, 101, 72, 92, 95, 98, 112, 100, 103, 99,
];

const List<int> _chromaBase = [
  17, 18, 24, 47, 99, 99, 99, 99, 18, 21, 26, 66, 99, 99, 99, 99, //
  24, 26, 56, 99, 99, 99, 99, 99, 47, 66, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
];

const List<int> _dcLumaCounts = [0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0];
const List<int> _dcChromaCounts = [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0];
const List<int> _dcValues = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

const List<int> _acLumaCounts = [0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125];
const List<int> _acLumaValues = [
  1, 2, 3, 0, 4, 17, 5, 18, 33, 49, 65, 6, 19, 81, 97, 7, 34, 113, 20, 50, 129, 145, 161, 8, //
  35, 66, 177, 193, 21, 82, 209, 240, 36, 51, 98, 114, 130, 9, 10, 22, 23, 24, 25, 26, 37, 38,
  39, 40, 41, 42, 52, 53, 54, 55, 56, 57, 58, 67, 68, 69, 70, 71, 72, 73, 74, 83, 84, 85, 86,
  87, 88, 89, 90, 99, 100, 101, 102, 103, 104, 105, 106, 115, 116, 117, 118, 119, 120, 121,
  122, 131, 132, 133, 134, 135, 136, 137, 138, 146, 147, 148, 149, 150, 151, 152, 153, 154,
  162, 163, 164, 165, 166, 167, 168, 169, 170, 178, 179, 180, 181, 182, 183, 184, 185, 186,
  194, 195, 196, 197, 198, 199, 200, 201, 202, 210, 211, 212, 213, 214, 215, 216, 217, 218,
  225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 241, 242, 243, 244, 245, 246, 247, 248,
  249, 250,
];

const List<int> _acChromaCounts = [0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 119];
const List<int> _acChromaValues = [
  0, 1, 2, 3, 17, 4, 5, 33, 49, 6, 18, 65, 81, 7, 97, 113, 19, 34, 50, 129, 8, 20, 66, 145, //
  161, 177, 193, 9, 35, 51, 82, 240, 21, 98, 114, 209, 10, 22, 36, 52, 225, 37, 241, 23, 24,
  25, 26, 38, 39, 40, 41, 42, 53, 54, 55, 56, 57, 58, 67, 68, 69, 70, 71, 72, 73, 74, 83, 84,
  85, 86, 87, 88, 89, 90, 99, 100, 101, 102, 103, 104, 105, 106, 115, 116, 117, 118, 119, 120,
  121, 122, 130, 131, 132, 133, 134, 135, 136, 137, 138, 146, 147, 148, 149, 150, 151, 152,
  153, 154, 162, 163, 164, 165, 166, 167, 168, 169, 170, 178, 179, 180, 181, 182, 183, 184,
  185, 186, 194, 195, 196, 197, 198, 199, 200, 201, 202, 210, 211, 212, 213, 214, 215, 216,
  217, 218, 226, 227, 228, 229, 230, 231, 232, 233, 234, 242, 243, 244, 245, 246, 247, 248,
  249, 250,
];
