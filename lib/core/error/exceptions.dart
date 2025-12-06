/// Base exception class
class AppException implements Exception {
  final String message;
  final String? details;

  AppException({required this.message, this.details});

  @override
  String toString() =>
      'AppException: $message${details != null ? ' - $details' : ''}';
}

/// Camera-related exceptions
class CameraException extends AppException {
  CameraException({required super.message, super.details});
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({required super.message, super.details});
}

/// Connection exceptions
class ConnectionException extends AppException {
  ConnectionException({required super.message, super.details});
}

/// Platform channel exceptions
class PlatformChannelException extends AppException {
  PlatformChannelException({required super.message, super.details});
}

class ServerException extends AppException {
  ServerException({super.message = 'Server Error', super.details});
}

class AuthException extends AppException {
  AuthException({super.message = 'Authentication Failed', super.details});
}
