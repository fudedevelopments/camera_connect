import '../../domain/entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();
  Future<void> toggleEventActive(String eventId, bool isActive);
}
