import 'package:equatable/equatable.dart';

import '../../domain/entities/camera.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/image.dart';
import '../../domain/entities/log_entry.dart';

/// Base camera state
abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CameraInitial extends CameraState {}

/// Loading state
class CameraLoading extends CameraState {}

/// Connection status state
class CameraConnectionState extends CameraState {
  final ConnectionStatus status;
  final String? cameraName;

  const CameraConnectionState({required this.status, this.cameraName});

  @override
  List<Object?> get props => [status, cameraName];
}

/// Cameras discovered state
class CamerasDiscovered extends CameraState {
  final List<Camera> cameras;

  const CamerasDiscovered(this.cameras);

  @override
  List<Object> get props => [cameras];
}

/// Images loaded state
class ImagesLoaded extends CameraState {
  final List<Image> images;

  const ImagesLoaded(this.images);

  @override
  List<Object> get props => [images];
}

/// Image downloaded state
class ImageDownloaded extends CameraState {
  final Image image;

  const ImageDownloaded(this.image);

  @override
  List<Object> get props => [image];
}

/// Log entry state
class CameraLogEntry extends CameraState {
  final LogEntry logEntry;

  const CameraLogEntry(this.logEntry);

  @override
  List<Object> get props => [logEntry];
}

/// Error state
class CameraError extends CameraState {
  final String message;
  final String? details;

  const CameraError({required this.message, this.details});

  @override
  List<Object?> get props => [message, details];
}

/// Success state (for generic success messages)
class CameraSuccess extends CameraState {
  final String message;

  const CameraSuccess(this.message);

  @override
  List<Object> get props => [message];
}
