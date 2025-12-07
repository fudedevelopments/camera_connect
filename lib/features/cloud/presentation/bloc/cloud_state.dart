import 'package:equatable/equatable.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/upload_status.dart';

abstract class CloudState extends Equatable {
  const CloudState();

  @override
  List<Object?> get props => [];
}

class CloudInitial extends CloudState {}

class CloudLoading extends CloudState {}

class CloudLoaded extends CloudState {
  final List<Event> events;
  final Map<String, List<UploadStatus>> uploadStatuses;

  const CloudLoaded({required this.events, this.uploadStatuses = const {}});

  @override
  List<Object?> get props => [events, uploadStatuses];

  CloudLoaded copyWith({
    List<Event>? events,
    Map<String, List<UploadStatus>>? uploadStatuses,
  }) {
    return CloudLoaded(
      events: events ?? this.events,
      uploadStatuses: uploadStatuses ?? this.uploadStatuses,
    );
  }
}

class CloudError extends CloudState {
  final String message;

  const CloudError({required this.message});

  @override
  List<Object?> get props => [message];
}

class EventToggling extends CloudState {
  final List<Event> events;
  final String togglingEventId;
  final Map<String, List<UploadStatus>> uploadStatuses;

  const EventToggling({
    required this.events,
    required this.togglingEventId,
    this.uploadStatuses = const {},
  });

  @override
  List<Object?> get props => [events, togglingEventId, uploadStatuses];
}
