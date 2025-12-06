import 'dart:convert';

import '../../domain/entities/camera.dart' as domain;

/// Camera model (Data Transfer Object)
/// Handles JSON serialization and extends domain entity
class CameraModel extends domain.Camera {
  const CameraModel({
    required super.ipAddress,
    required super.port,
    super.name,
    super.manufacturer,
    required super.discoveryMethod,
  });

  factory CameraModel.fromMap(Map<String, dynamic> map) {
    return CameraModel(
      ipAddress: map['ipAddress'] ?? '',
      port: map['port'] ?? 15740,
      name: map['name'],
      manufacturer: map['manufacturer'],
      discoveryMethod: map['discoveryMethod'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ipAddress': ipAddress,
      'port': port,
      'name': name,
      'manufacturer': manufacturer,
      'discoveryMethod': discoveryMethod,
    };
  }

  String toJson() => json.encode(toMap());

  factory CameraModel.fromJson(String source) =>
      CameraModel.fromMap(json.decode(source));

  /// Convert domain entity to model
  factory CameraModel.fromEntity(domain.Camera camera) {
    return CameraModel(
      ipAddress: camera.ipAddress,
      port: camera.port,
      name: camera.name,
      manufacturer: camera.manufacturer,
      discoveryMethod: camera.discoveryMethod,
    );
  }

  /// Convert to domain entity
  domain.Camera toEntity() {
    return domain.Camera(
      ipAddress: ipAddress,
      port: port,
      name: name,
      manufacturer: manufacturer,
      discoveryMethod: discoveryMethod,
    );
  }
}
