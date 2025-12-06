import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/camera.dart';
import '../entities/connection_status.dart';
import '../entities/image.dart';
import '../entities/log_entry.dart';

/// Camera repository interface (contract)
/// Data layer will implement this
abstract class CameraRepository {
  /// Discover cameras on the network
  Future<Either<Failure, List<Camera>>> discoverCameras();

  /// Connect to a specific camera
  Future<Either<Failure, void>> connectToCamera(String ipAddress, int port);

  /// Disconnect from current camera
  Future<Either<Failure, void>> disconnect();

  /// Get current connection status
  Stream<ConnectionStatus> getConnectionStatus();

  /// Get camera images
  Future<Either<Failure, List<Image>>> getCameraImages();

  /// Download full image data
  Future<Either<Failure, Image>> downloadImage(String objectHandle);

  /// Get log entries stream
  Stream<LogEntry> getLogStream();

  /// Get images stream
  Stream<List<Image>> getImagesStream();
}
