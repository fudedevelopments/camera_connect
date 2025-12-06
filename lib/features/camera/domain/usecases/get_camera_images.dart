import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/image.dart';
import '../repositories/camera_repository.dart';

/// Use case for getting camera images
class GetCameraImages implements UseCase<List<Image>, NoParams> {
  final CameraRepository repository;

  GetCameraImages(this.repository);

  @override
  Future<Either<Failure, List<Image>>> call(NoParams params) async {
    return await repository.getCameraImages();
  }
}
