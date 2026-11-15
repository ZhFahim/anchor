import 'dart:io';

import 'package:image/image.dart' as img;

import 'image_compressor.dart';

const _jpegQuality = 85;
const _maxDimension = 2048;

/// Compresses [image] in a background isolate.
///
/// This is a top-level function so it can be passed to [compute] or
/// [Isolate.run].
Future<CompressedImage> compressImageIsolate(SourceImage image) async {
  final bytes = await File(image.path).readAsBytes();
  final originalSize = bytes.length;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('Cannot decode image: ${image.path}');
  }

  // Only downscale; never upscale.
  img.Image resized = decoded;
  if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
    resized = img.copyResize(
      decoded,
      width: _maxDimension,
      height: _maxDimension,
    );
  }

  final jpeg = img.encodeJpg(resized, quality: _jpegQuality);

  final dir = await Directory.systemTemp.createTemp('anchor_compress');
  final out = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
  await out.writeAsBytes(jpeg);

  return CompressedImage(
    path: out.path,
    mime: 'image/jpeg',
    originalSize: originalSize,
    compressedSize: jpeg.length,
  );
}