import 'package:equatable/equatable.dart';

/// Camera entity - domain model (pure Dart, no JSON logic)
class Camera extends Equatable {
  final String ipAddress;
  final int port;
  final String? name;
  final String? manufacturer;
  final String discoveryMethod;

  const Camera({
    required this.ipAddress,
    required this.port,
    this.name,
    this.manufacturer,
    required this.discoveryMethod,
  });

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (manufacturer != null && manufacturer!.isNotEmpty) {
      return '$manufacturer Camera';
    }
    return 'Camera at $ipAddress';
  }

  @override
  List<Object?> get props => [
    ipAddress,
    port,
    name,
    manufacturer,
    discoveryMethod,
  ];

  @override
  String toString() => 'Camera($displayName, $ipAddress:$port)';
}
