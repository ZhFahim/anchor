/// Defines the interface for image compression on the local device.
///
/// Implementations should run compression work off the UI thread.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'image_compressor_worker.dart'
    show CompressedImage, SourceImage, compressImageIsolate;

abstract interface class ImageCompressor {
  /// Compresses [image] and returns the result.
  Future<CompressedImage> compress(SourceImage image);
}

/// Compresses using a background isolate. Override in tests.
final imageCompressorProvider = Provider<ImageCompressor>(
  (ref) => _ComputeImageCompressor(),
);

class _ComputeImageCompressor implements ImageCompressor {
  @override
  Future<CompressedImage> compress(SourceImage image) =>
      compute(compressImageIsolate, image);
}