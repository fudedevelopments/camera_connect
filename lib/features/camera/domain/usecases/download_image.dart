import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/image.dart';
import '../repositories/camera_repository.dart';

/// Use case for downloading full image
class DownloadImage implements UseCase<Image, DownloadImageParams> {
  final CameraRepository repository;

  DownloadImage(this.repository);

  @override
  Future<Either<Failure, Image>> call(DownloadImageParams params) async {
    return await repository.downloadImage(params.objectHandle);
  }
}

class DownloadImageParams extends Equatable {
  final String objectHandle;

  const DownloadImageParams({required this.objectHandle});

  @override
  List<Object> get props => [objectHandle];
}
