/// Event entity - Domain layer
class Event {
  final String id;
  final String photographerId;
  final String eventName;
  final int eventDate;
  final String eventLocation;
  final String qrCode;
  final String uniqueUrl;
  final String fullEventUrl;
  final String description;
  final bool isActive;
  final bool isPublished;
  final int createdAt;
  final int updatedAt;

  const Event({
    required this.id,
    required this.photographerId,
    required this.eventName,
    required this.eventDate,
    required this.eventLocation,
    required this.qrCode,
    required this.uniqueUrl,
    required this.fullEventUrl,
    required this.description,
    required this.isActive,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });
}
