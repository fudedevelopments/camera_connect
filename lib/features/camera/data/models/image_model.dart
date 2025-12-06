import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/image.dart' as domain;

/// Image model (Data Transfer Object)
/// Handles JSON serialization and extends domain entity
class ImageModel extends domain.Image {
  const ImageModel({
    required super.objectHandle,
    required super.filename,
    required super.size,
    required super.format,
    super.thumbnailData,
    super.imageData,
    super.captureDate,
    super.width,
    super.height,
  });

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
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

  String toJson() => json.encode(toMap());

  factory ImageModel.fromJson(String source) =>
      ImageModel.fromMap(json.decode(source));

  /// Convert domain entity to model
  factory ImageModel.fromEntity(domain.Image image) {
    return ImageModel(
      objectHandle: image.objectHandle,
      filename: image.filename,
      size: image.size,
      format: image.format,
      thumbnailData: image.thumbnailData,
      imageData: image.imageData,
      captureDate: image.captureDate,
      width: image.width,
      height: image.height,
    );
  }

  /// Convert to domain entity
  domain.Image toEntity() {
    return domain.Image(
      objectHandle: objectHandle,
      filename: filename,
      size: size,
      format: format,
      thumbnailData: thumbnailData,
      imageData: imageData,
      captureDate: captureDate,
      width: width,
      height: height,
    );
  }

  ImageModel copyWith({
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
    return ImageModel(
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
}
