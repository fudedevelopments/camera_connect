import 'dart:convert';
import 'dart:typed_data';

/// Camera image model representing an image on the camera
class CameraImage {
  final String objectHandle;
  final String filename;
  final int size;
  final String format;
  final Uint8List? thumbnailData;
  final Uint8List? imageData;
  final DateTime? captureDate;
  final int? width;
  final int? height;

  CameraImage({
    required this.objectHandle,
    required this.filename,
    required this.size,
    required this.format,
    this.thumbnailData,
    this.imageData,
    this.captureDate,
    this.width,
    this.height,
  });

  factory CameraImage.fromMap(Map<String, dynamic> map) {
    return CameraImage(
      objectHandle: map['objectHandle']?.toString() ?? '',
      filename: map['filename'] ?? 'Unknown',
      size: map['size'] ?? 0,
      format: map['format'] ?? 'Unknown',
      thumbnailData: map['thumbnail'] != null
          ? base64Decode(map['thumbnail'])
          : null,
      imageData: map['imageData'] != null
          ? base64Decode(map['imageData'])
          : null,
      captureDate: map['captureDate'] != null
          ? DateTime.tryParse(map['captureDate'])
          : null,
      width: map['width'],
      height: map['height'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'objectHandle': objectHandle,
      'filename': filename,
      'size': size,
      'format': format,
      'thumbnail': thumbnailData != null ? base64Encode(thumbnailData!) : null,
      'imageData': imageData != null ? base64Encode(imageData!) : null,
      'captureDate': captureDate?.toIso8601String(),
      'width': width,
      'height': height,
    };
  }

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file extension
  String get extension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : format;
  }

  /// Check if image is a RAW file
  bool get isRaw {
    final ext = extension.toLowerCase();
    return [
      'raw',
      'cr2',
      'cr3',
      'nef',
      'arw',
      'orf',
      'rw2',
      'dng',
    ].contains(ext);
  }

  /// Check if image is a video
  bool get isVideo {
    final ext = extension.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'mts', 'avchd'].contains(ext);
  }

  CameraImage copyWith({
    String? objectHandle,
    String? filename,
    int? size,
    String? format,
    Uint8List? thumbnailData,
    Uint8List? imageData,
    DateTime? captureDate,
    int? width,
    int? height,
  }) {
    return CameraImage(
      objectHandle: objectHandle ?? this.objectHandle,
      filename: filename ?? this.filename,
      size: size ?? this.size,
      format: format ?? this.format,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      imageData: imageData ?? this.imageData,
      captureDate: captureDate ?? this.captureDate,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String toString() {
    return 'CameraImage(handle: $objectHandle, filename: $filename, size: $formattedSize)';
  }
}
