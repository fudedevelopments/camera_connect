/// Discovered camera model from network discovery
class DiscoveredCamera {
  final String ipAddress;
  final int port;
  final String? name;
  final String? manufacturer;
  final String discoveryMethod;

  DiscoveredCamera({
    required this.ipAddress,
    required this.port,
    this.name,
    this.manufacturer,
    required this.discoveryMethod,
  });

  factory DiscoveredCamera.fromMap(Map<String, dynamic> map) {
    return DiscoveredCamera(
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
  String toString() {
    return 'DiscoveredCamera($displayName, $ipAddress:$port)';
  }
}
