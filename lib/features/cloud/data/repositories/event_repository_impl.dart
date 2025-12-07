import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Event>> getEvents() async {
    final eventModels = await remoteDataSource.getEvents();
    return eventModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> toggleEventActive(String eventId, bool isActive) async {
    await remoteDataSource.toggleEventActive(eventId, isActive);
  }
}
