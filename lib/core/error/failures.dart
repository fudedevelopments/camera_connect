import 'package:equatable/equatable.dart';

/// Base class for all failures in the app
abstract class Failure extends Equatable {
  final String message;
  final String? details;

  const Failure({required this.message, this.details});

  @override
  List<Object?> get props => [message, details];
}

/// Camera-related failures
class CameraFailure extends Failure {
  const CameraFailure({required super.message, super.details});
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.details});
}

/// Connection failures
class ConnectionFailure extends Failure {
  const ConnectionFailure({required super.message, super.details});
}

/// Platform channel failures
class PlatformChannelFailure extends Failure {
  const PlatformChannelFailure({required super.message, super.details});
}

/// Auth-related failures
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.details});
}
