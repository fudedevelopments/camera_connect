import '../../domain/entities/event.dart';

/// Event model - Data layer (DTO)
class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.photographerId,
    required super.eventName,
    required super.eventDate,
    required super.eventLocation,
    required super.qrCode,
    required super.uniqueUrl,
    required super.fullEventUrl,
    required super.description,
    required super.isActive,
    required super.isPublished,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      photographerId: json['photographer_id'] as String,
      eventName: json['event_name'] as String,
      eventDate: json['event_date'] as int,
      eventLocation: json['event_location'] as String,
      qrCode: json['qr_code'] as String,
      uniqueUrl: json['unique_url'] as String,
      fullEventUrl: json['full_event_url'] as String,
      description: json['description'] as String,
      isActive: json['is_active'] as bool,
      isPublished: json['is_published'] as bool,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photographer_id': photographerId,
      'event_name': eventName,
      'event_date': eventDate,
      'event_location': eventLocation,
      'qr_code': qrCode,
      'unique_url': uniqueUrl,
      'full_event_url': fullEventUrl,
      'description': description,
      'is_active': isActive,
      'is_published': isPublished,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Event toEntity() {
    return Event(
      id: id,
      photographerId: photographerId,
      eventName: eventName,
      eventDate: eventDate,
      eventLocation: eventLocation,
      qrCode: qrCode,
      uniqueUrl: uniqueUrl,
      fullEventUrl: fullEventUrl,
      description: description,
      isActive: isActive,
      isPublished: isPublished,
      isSynced: false, // Always false from API, sync is local only
      autoUpload: false, // Always false from API, auto-upload is local only
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
