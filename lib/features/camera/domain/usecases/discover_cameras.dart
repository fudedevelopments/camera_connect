import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/camera.dart';
import '../repositories/camera_repository.dart';

/// Use case for discovering cameras on the network
class DiscoverCameras implements UseCase<List<Camera>, NoParams> {
  final CameraRepository repository;

  DiscoverCameras(this.repository);

  @override
  Future<Either<Failure, List<Camera>>> call(NoParams params) async {
    return await repository.discoverCameras();
  }
}
