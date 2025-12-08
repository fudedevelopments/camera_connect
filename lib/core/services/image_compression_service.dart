import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for compressing images before upload
/// Ensures images are between 500KB-700KB with quality preservation
class ImageCompressionService {
  // Size thresholds in bytes
  static const int minTargetSize = 500 * 1024; // 500 KB
  static const int maxTargetSize = 700 * 1024; // 700 KB
  static const int compressionThreshold =
      700 * 1024; // Only compress if above 700 KB

  /// Compress image if it exceeds the threshold
  /// Returns the compressed file or original if already within limits
  Future<File> compressImageIfNeeded(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      final fileSizeStr = getFileSizeString(fileSize);
      final fileName = path.basename(imageFile.path);

      developer.log('📸 Image Compression Check', name: 'ImageCompression');
      developer.log('  File: $fileName', name: 'ImageCompression');
      developer.log(
        '  Original Size: $fileSizeStr ($fileSize bytes)',
        name: 'ImageCompression',
      );

      // If file is already within acceptable range, return original
      if (fileSize <= maxTargetSize) {
        developer.log(
          '✅ Image already within acceptable size (≤700 KB). No compression needed.',
          name: 'ImageCompression',
        );
        return imageFile;
      }

      developer.log(
        '🔄 Image exceeds 700 KB. Starting compression...',
        name: 'ImageCompression',
      );

      // If file needs compression
      final result = await _compressImage(imageFile, fileSize);
      final resultSize = await result.length();
      final resultSizeStr = getFileSizeString(resultSize);

      developer.log('✅ Compression Complete', name: 'ImageCompression');
      developer.log(
        '  Final Size: $resultSizeStr ($resultSize bytes)',
        name: 'ImageCompression',
      );
      developer.log(
        '  Size Reduction: ${((1 - resultSize / fileSize) * 100).toStringAsFixed(1)}%',
        name: 'ImageCompression',
      );

      return result;
    } catch (e) {
      developer.log(
        '❌ Compression Error: $e',
        name: 'ImageCompression',
        error: e,
      );
      developer.log(
        '⚠️  Falling back to original file',
        name: 'ImageCompression',
      );
      // If compression fails, return original file
      return imageFile;
    }
  }

  /// Internal method to compress image with adaptive quality
  Future<File> _compressImage(File imageFile, int originalSize) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final fileExtension = path.extension(imageFile.path);
      final targetPath = path.join(
        tempDir.path,
        '${fileName}_compressed$fileExtension',
      );

      developer.log(
        '  Target: ${getFileSizeString(minTargetSize)} - ${getFileSizeString(maxTargetSize)}',
        name: 'ImageCompression',
      );

      // Start with high quality and adjust if needed
      int quality = 95;
      File? compressedFile;
      int compressedSize = originalSize;
      int iteration = 0;

      // Adaptive compression: reduce quality until we hit target size
      while (quality >= 70 && compressedSize > maxTargetSize) {
        iteration++;
        developer.log(
          '  Iteration $iteration: Trying quality $quality%...',
          name: 'ImageCompression',
        );

        final result = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          targetPath,
          quality: quality,
          format: _getCompressFormat(fileExtension),
          keepExif: true, // Preserve metadata
        );

        if (result == null) {
          developer.log(
            '    ⚠️  Compression returned null',
            name: 'ImageCompression',
          );
          break;
        }

        compressedFile = File(result.path);
        compressedSize = await compressedFile.length();

        developer.log(
          '    Result: ${getFileSizeString(compressedSize)} ($compressedSize bytes)',
          name: 'ImageCompression',
        );

        // If we're within the target range, we're done
        if (compressedSize >= minTargetSize &&
            compressedSize <= maxTargetSize) {
          developer.log(
            '    ✅ Perfect! Within target range.',
            name: 'ImageCompression',
          );
          return compressedFile;
        }

        // If file is too small, use previous iteration or original
        if (compressedSize < minTargetSize) {
          developer.log(
            '    ⚠️  File too small (< ${getFileSizeString(minTargetSize)})',
            name: 'ImageCompression',
          );
          // Quality is too low, revert to higher quality
          if (quality < 95) {
            quality += 5; // Step back
            developer.log(
              '    🔄 Reverting to quality ${quality}%...',
              name: 'ImageCompression',
            );
            final finalResult = await FlutterImageCompress.compressAndGetFile(
              imageFile.absolute.path,
              targetPath,
              quality: quality,
              format: _getCompressFormat(fileExtension),
              keepExif: true,
            );
            if (finalResult != null) {
              final finalFile = File(finalResult.path);
              final finalSize = await finalFile.length();
              developer.log(
                '    Final: ${getFileSizeString(finalSize)} at $quality% quality',
                name: 'ImageCompression',
              );
              return finalFile;
            }
          }
          break;
        }

        developer.log(
          '    Still too large, reducing quality...',
          name: 'ImageCompression',
        );

        // Reduce quality for next iteration
        quality -= 5;
      }

      // If we have a compressed file that's smaller than original, use it
      if (compressedFile != null && compressedSize < originalSize) {
        developer.log(
          '  Using compressed file (${getFileSizeString(compressedSize)} < original)',
          name: 'ImageCompression',
        );
        return compressedFile;
      }

      developer.log(
        '  ⚠️  Keeping original file (compression didn\'t improve size)',
        name: 'ImageCompression',
      );
      // Otherwise return original
      return imageFile;
    } catch (e) {
      developer.log(
        '  ❌ Compression Error: $e',
        name: 'ImageCompression',
        error: e,
      );
      // If any error occurs, return original file
      return imageFile;
    }
  }

  /// Get compression format based on file extension
  CompressFormat _getCompressFormat(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return CompressFormat.png;
      case '.jpg':
      case '.jpeg':
        return CompressFormat.jpeg;
      case '.heic':
        return CompressFormat.heic;
      case '.webp':
        return CompressFormat.webp;
      default:
        return CompressFormat.jpeg; // Default to JPEG
    }
  }

  /// Get the file size in a human-readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Check if file needs compression
  Future<bool> needsCompression(File imageFile) async {
    final fileSize = await imageFile.length();
    return fileSize > compressionThreshold;
  }

  /// Get file size in bytes
  Future<int> getFileSize(File imageFile) async {
    return await imageFile.length();
  }
}
