import 'dart:typed_data';

import 'package:anchor/features/auth/data/qr/qr_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxing2/qrcode.dart';

/// [text] as a QR code, [scale] pixels a module, on a white margin, with
/// rows [bytesPerRow] apart when given.
({Uint8List pixels, int size}) _render(
  String text, {
  int scale = 4,
  int margin = 16,
  int? bytesPerRow,
}) {
  final matrix = Encoder.encode(text, ErrorCorrectionLevel.m).matrix!;
  final size = matrix.width * scale + 2 * margin;
  final stride = bytesPerRow ?? size;
  final pixels = Uint8List(stride * size)..fillRange(0, stride * size, 0xFF);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final mx = (x - margin) ~/ scale;
      final my = (y - margin) ~/ scale;
      final isDark =
          x >= margin &&
          y >= margin &&
          mx < matrix.width &&
          my < matrix.height &&
          matrix.get(mx, my) == 1;
      if (isDark) pixels[y * stride + x] = 0;
    }
  }
  return (pixels: pixels, size: size);
}

void main() {
  const link = 'https://notes.example.com/magic-login?code=AbC-123_xyz';

  test('reads a QR code', () {
    final image = _render(link);
    expect(decodeQr(image.pixels, image.size, image.size), link);
  });

  test('reads camera rows that are padded', () {
    final image = _render(link, bytesPerRow: 256);
    final packed = packRows(image.pixels, image.size, image.size, 256);
    expect(decodeQr(packed, image.size, image.size), link);
  });

  test('finds nothing in a blank picture', () {
    final blank = Uint8List(200 * 200)..fillRange(0, 200 * 200, 0x80);
    expect(decodeQr(blank, 200, 200), isNull);
  });
}
