import 'dart:io';

import 'package:image/image.dart' as img;

/// A source image to be compressed.
class SourceImage {
  const SourceImage({required this.path, required this.mime});

  final String path;
  final String mime;
}

/// The result of compressing an image.
class CompressedImage {
  const CompressedImage({
    required this.path,
    required this.mime,
    required this.originalSize,
    required this.compressedSize,
  });

  final String path;
  final String mime;
  final int originalSize;
  final int compressedSize;
}

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