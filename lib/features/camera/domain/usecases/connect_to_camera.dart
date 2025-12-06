import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/camera_repository.dart';

/// Use case for connecting to a camera
class ConnectToCamera implements UseCase<void, ConnectParams> {
  final CameraRepository repository;

  ConnectToCamera(this.repository);

  @override
  Future<Either<Failure, void>> call(ConnectParams params) async {
    return await repository.connectToCamera(params.ipAddress, params.port);
  }
}

class ConnectParams extends Equatable {
  final String ipAddress;
  final int port;

  const ConnectParams({required this.ipAddress, required this.port});

  @override
  List<Object> get props => [ipAddress, port];
}
