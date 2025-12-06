import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/camera_repository.dart';

/// Use case for disconnecting from camera
class DisconnectCamera implements UseCase<void, NoParams> {
  final CameraRepository repository;

  DisconnectCamera(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.disconnect();
  }
}
