/// Defines the interface for image compression on the local device.
///
/// Implementations should run compression work off the UI thread.
abstract interface class ImageCompressor {
  /// Compresses [image] and returns the result.
  Future<CompressedImage> compress(SourceImage image);
}

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