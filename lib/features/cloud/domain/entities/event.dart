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
  final bool isSynced; // Sync status for local folder
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
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Event copyWith({
    String? id,
    String? photographerId,
    String? eventName,
    int? eventDate,
    String? eventLocation,
    String? qrCode,
    String? uniqueUrl,
    String? fullEventUrl,
    String? description,
    bool? isActive,
    bool? isPublished,
    bool? isSynced,
    int? createdAt,
    int? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      photographerId: photographerId ?? this.photographerId,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      qrCode: qrCode ?? this.qrCode,
      uniqueUrl: uniqueUrl ?? this.uniqueUrl,
      fullEventUrl: fullEventUrl ?? this.fullEventUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
