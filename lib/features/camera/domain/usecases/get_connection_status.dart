import '../entities/connection_status.dart';
import '../repositories/camera_repository.dart';

/// Use case for getting connection status stream
class GetConnectionStatus {
  final CameraRepository repository;

  GetConnectionStatus(this.repository);

  Stream<ConnectionStatus> call() {
    return repository.getConnectionStatus();
  }
}
