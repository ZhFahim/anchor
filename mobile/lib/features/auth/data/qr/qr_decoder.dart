import 'dart:typed_data';

import 'package:zxing2/qrcode.dart';

/// Reads the QR code in a greyscale picture ([width] × [height], one byte a
/// pixel, such as the Y plane of a camera frame). Null when there is none.
///
/// Pure Dart (zxing2), unlike ML Kit, so the F-Droid build scans too.
String? decodeQr(Uint8List grey, int width, int height) {
  final source = _GreyLuminanceSource(
    Int8List.view(grey.buffer, grey.offsetInBytes, width * height),
    width,
    height,
  );
  try {
    return QRCodeReader().decode(BinaryBitmap(HybridBinarizer(source))).text;
  } on ReaderException {
    return null;
  }
}

/// [plane] rows are [bytesPerRow] apart, which may be more than [width].
Uint8List packRows(Uint8List plane, int width, int height, int bytesPerRow) {
  if (bytesPerRow == width) return Uint8List.fromList(plane);
  final packed = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    packed.setRange(y * width, (y + 1) * width, plane, y * bytesPerRow);
  }
  return packed;
}

class _GreyLuminanceSource extends LuminanceSource {
  _GreyLuminanceSource(this._pixels, super.width, super.height);

  final Int8List _pixels;

  @override
  Int8List getRow(int y, Int8List? row) {
    if (row == null || row.length < width) row = Int8List(width);
    row.setRange(0, width, _pixels, y * width);
    return row;
  }

  @override
  Int8List getMatrix() => _pixels;
}
