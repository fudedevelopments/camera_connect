import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/camera.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/image.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/camera_repository.dart';
import '../datasources/camera_local_data_source.dart';
import '../datasources/camera_remote_data_source.dart';

/// Camera repository implementation
/// Implements the domain repository interface
/// Handles data layer operations and error mapping
class CameraRepositoryImpl implements CameraRepository {
  final CameraRemoteDataSource remoteDataSource;
  final CameraLocalDataSource localDataSource;

  CameraRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Camera>>> discoverCameras() async {
    try {
      final cameraModels = await remoteDataSource.discoverCameras();
      // Models already extend entities, so we can return them directly
      return Right(cameraModels);
    } on CameraException catch (e) {
      return Left(CameraFailure(message: e.message, details: e.details));
    } on PlatformChannelException catch (e) {
      return Left(
        PlatformChannelFailure(message: e.message, details: e.details),
      );
    } catch (e) {
      return Left(
        CameraFailure(message: 'Unexpected error', details: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> connectToCamera(
    String ipAddress,
    int port,
  ) async {
    try {
      await remoteDataSource.connectToCamera(ipAddress, port);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message, details: e.details));
    } on PlatformChannelException catch (e) {
      return Left(
        PlatformChannelFailure(message: e.message, details: e.details),
      );
    } catch (e) {
      return Left(
        ConnectionFailure(message: 'Unexpected error', details: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await remoteDataSource.disconnect();
      return const Right(null);
    } on PlatformChannelException catch (e) {
      return Left(
        PlatformChannelFailure(message: e.message, details: e.details),
      );
    } catch (e) {
      return Left(
        ConnectionFailure(message: 'Unexpected error', details: e.toString()),
      );
    }
  }

  @override
  Stream<ConnectionStatus> getConnectionStatus() {
    return remoteDataSource.getConnectionStatusStream();
  }

  @override
  Future<Either<Failure, List<Image>>> getCameraImages() async {
    try {
      final imageModels = await remoteDataSource.getCameraImages();
      // Models already extend entities, so we can return them directly
      return Right(imageModels);
    } on PlatformChannelException catch (e) {
      return Left(
        PlatformChannelFailure(message: e.message, details: e.details),
      );
    } catch (e) {
      return Left(
        CameraFailure(message: 'Failed to get images', details: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, Image>> downloadImage(String objectHandle) async {
    try {
      final imageModel = await remoteDataSource.downloadImage(objectHandle);
      return Right(imageModel);
    } on CameraException catch (e) {
      return Left(CameraFailure(message: e.message, details: e.details));
    } on PlatformChannelException catch (e) {
      return Left(
        PlatformChannelFailure(message: e.message, details: e.details),
      );
    } catch (e) {
      return Left(
        CameraFailure(message: 'Download failed', details: e.toString()),
      );
    }
  }

  @override
  Stream<LogEntry> getLogStream() {
    return remoteDataSource.getLogStream();
  }

  @override
  Stream<List<Image>> getImagesStream() {
    return remoteDataSource.getImagesStream();
  }
}
