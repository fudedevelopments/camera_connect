import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/get_events.dart';
import '../../domain/usecases/toggle_event_active.dart';
import 'cloud_event.dart';
import 'cloud_state.dart';

class CloudBloc extends Bloc<CloudEvent, CloudState> {
  final GetEventsUseCase getEventsUseCase;
  final ToggleEventActiveUseCase toggleEventActiveUseCase;

  CloudBloc({
    required this.getEventsUseCase,
    required this.toggleEventActiveUseCase,
  }) : super(CloudInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<ToggleEventStatus>(_onToggleEventStatus);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<CloudState> emit) async {
    emit(CloudLoading());
    try {
      final events = await getEventsUseCase();
      emit(CloudLoaded(events: events));
    } catch (e) {
      emit(CloudError(message: e.toString()));
    }
  }

  Future<void> _onToggleEventStatus(
    ToggleEventStatus event,
    Emitter<CloudState> emit,
  ) async {
    final currentState = state;
    if (currentState is CloudLoaded) {
      // Just update the UI state, no API call
      final updatedEvents = currentState.events.map((e) {
        if (e.id == event.eventId) {
          return Event(
            id: e.id,
            photographerId: e.photographerId,
            eventName: e.eventName,
            eventDate: e.eventDate,
            eventLocation: e.eventLocation,
            qrCode: e.qrCode,
            uniqueUrl: e.uniqueUrl,
            fullEventUrl: e.fullEventUrl,
            description: e.description,
            isActive: event.isActive,
            isPublished: e.isPublished,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          );
        }
        return e;
      }).toList();

      emit(CloudLoaded(events: updatedEvents));
    }
  }
}
