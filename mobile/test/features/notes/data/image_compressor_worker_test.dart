import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:anchor/features/notes/data/image_compressor.dart';
import 'package:anchor/features/notes/data/image_compressor_worker.dart';

void main() {
  test('compressImageIsolate returns a JPEG path with compressed size', () async {
    final tempDir = await Directory.systemTemp.createTemp('anchor_test');
    final inputFile = File('${tempDir.path}/input.jpg');
    await inputFile.writeAsBytes(_createTestJpeg(200, 200));

    final source = SourceImage(path: inputFile.path, mime: 'image/jpeg');
    final result = await compressImageIsolate(source);

    expect(result.path, endsWith('.jpg'));
    expect(result.mime, 'image/jpeg');
    expect(result.originalSize, greaterThan(0));
    expect(result.compressedSize, greaterThan(0));

    final outputFile = File(result.path);
    expect(await outputFile.exists(), isTrue);
    final outputBytes = await outputFile.readAsBytes();
    expect(outputBytes.length, result.compressedSize);

    await tempDir.delete(recursive: true);
  });

  test('compressImageIsolate does not upscale small images', () async {
    final tempDir = await Directory.systemTemp.createTemp('anchor_test');
    final inputFile = File('${tempDir.path}/input.jpg');
    await inputFile.writeAsBytes(_createTestJpeg(50, 50));

    final source = SourceImage(path: inputFile.path, mime: 'image/jpeg');
    final result = await compressImageIsolate(source);

    final outputBytes = await File(result.path).readAsBytes();
    final decoded = img.decodeJpg(outputBytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(50));
    expect(decoded.height, lessThanOrEqualTo(50));

    await tempDir.delete(recursive: true);
  });

  test('compressImageIsolate handles decode failure', () async {
    final tempDir = await Directory.systemTemp.createTemp('anchor_test');
    final inputFile = File('${tempDir.path}/input.jpg');
    await inputFile.writeAsBytes([1, 2, 3, 4, 5]);

    final source = SourceImage(path: inputFile.path, mime: 'image/jpeg');
    expect(
      () => compressImageIsolate(source),
      throwsA(isA<Exception>()),
    );

    await tempDir.delete(recursive: true);
  });
}

/// Creates a test JPEG image of the given size with a simple gradient pattern.
List<int> _createTestJpeg(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixel(x, y, img.ColorRgb8(x % 256, y % 256, (x + y) % 256));
    }
  }
  return img.encodeJpg(image, quality: 70);
}