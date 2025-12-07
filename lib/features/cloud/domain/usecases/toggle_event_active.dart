import '../repositories/event_repository.dart';

class ToggleEventActiveUseCase {
  final EventRepository repository;

  ToggleEventActiveUseCase(this.repository);

  Future<void> call(String eventId, bool isActive) async {
    return await repository.toggleEventActive(eventId, isActive);
  }
}
