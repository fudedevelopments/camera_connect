import 'package:equatable/equatable.dart';

/// Base camera event
abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

/// Discover cameras event
class DiscoverCamerasEvent extends CameraEvent {}

/// Connect to camera event
class ConnectToCameraEvent extends CameraEvent {
  final String ipAddress;
  final int port;

  const ConnectToCameraEvent({required this.ipAddress, required this.port});

  @override
  List<Object> get props => [ipAddress, port];
}

/// Disconnect event
class DisconnectCameraEvent extends CameraEvent {}

/// Get images event
class GetCameraImagesEvent extends CameraEvent {}

/// Download image event
class DownloadImageEvent extends CameraEvent {
  final String objectHandle;

  const DownloadImageEvent(this.objectHandle);

  @override
  List<Object> get props => [objectHandle];
}

/// Refresh images event
class RefreshImagesEvent extends CameraEvent {}

/// Initialize camera event (sets up streams)
class InitializeCameraEvent extends CameraEvent {}
