import 'package:equatable/equatable.dart';

abstract class CloudEvent extends Equatable {
  const CloudEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends CloudEvent {}

class ToggleEventStatus extends CloudEvent {
  final String eventId;
  final bool isActive;

  const ToggleEventStatus({required this.eventId, required this.isActive});

  @override
  List<Object?> get props => [eventId, isActive];
}

class ToggleEventSync extends CloudEvent {
  final String eventId;
  final String eventName;
  final bool isSynced;

  const ToggleEventSync({
    required this.eventId,
    required this.eventName,
    required this.isSynced,
  });

  @override
  List<Object?> get props => [eventId, eventName, isSynced];
}

class ToggleAutoUpload extends CloudEvent {
  final String eventId;
  final String eventName;
  final bool autoUpload;

  const ToggleAutoUpload({
    required this.eventId,
    required this.eventName,
    required this.autoUpload,
  });

  @override
  List<Object?> get props => [eventId, eventName, autoUpload];
}

/// Internal event to update upload statuses in the state
class UpdateUploadStatuses extends CloudEvent {
  const UpdateUploadStatuses();
}
