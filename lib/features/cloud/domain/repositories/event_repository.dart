import '../../domain/entities/event.dart';
import '../entities/upload_url.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();
  Future<void> toggleEventActive(String eventId, bool isActive);
  Future<UploadUrl> getUploadUrl({
    required String eventId,
    required String photoName,
    required String contentType,
  });
}
