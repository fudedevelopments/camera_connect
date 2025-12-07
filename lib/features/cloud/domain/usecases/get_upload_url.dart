import '../entities/upload_url.dart';
import '../repositories/event_repository.dart';

/// Use case for getting presigned upload URL
class GetUploadUrl {
  final EventRepository repository;

  GetUploadUrl(this.repository);

  Future<UploadUrl> call({
    required String eventId,
    required String photoName,
    required String contentType,
  }) async {
    return await repository.getUploadUrl(
      eventId: eventId,
      photoName: photoName,
      contentType: contentType,
    );
  }
}
