import 'package:equatable/equatable.dart';
import '../../domain/entities/event.dart';

abstract class CloudState extends Equatable {
  const CloudState();

  @override
  List<Object?> get props => [];
}

class CloudInitial extends CloudState {}

class CloudLoading extends CloudState {}

class CloudLoaded extends CloudState {
  final List<Event> events;

  const CloudLoaded({required this.events});

  @override
  List<Object?> get props => [events];
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

  const EventToggling({required this.events, required this.togglingEventId});

  @override
  List<Object?> get props => [events, togglingEventId];
}
