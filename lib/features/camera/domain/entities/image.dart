import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Image entity - domain model
class Image extends Equatable {
  final String objectHandle;
  final String filename;
  final int size;
  final String format;
  final Uint8List? thumbnailData;
  final Uint8List? imageData;
  final DateTime? captureDate;
  final int? width;
  final int? height;

  const Image({
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

  bool get hasThumbnail => thumbnailData != null;
  bool get hasFullImage => imageData != null;

  @override
  List<Object?> get props => [
    objectHandle,
    filename,
    size,
    format,
    thumbnailData,
    imageData,
    captureDate,
    width,
    height,
  ];
}
