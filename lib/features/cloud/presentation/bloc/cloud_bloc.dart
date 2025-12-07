import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/folder_service.dart';
import '../../domain/usecases/get_events.dart';
import '../../domain/usecases/toggle_event_active.dart';
import 'cloud_event.dart';
import 'cloud_state.dart';

class CloudBloc extends Bloc<CloudEvent, CloudState> {
  final GetEventsUseCase getEventsUseCase;
  final ToggleEventActiveUseCase toggleEventActiveUseCase;
  final FolderService folderService;

  CloudBloc({
    required this.getEventsUseCase,
    required this.toggleEventActiveUseCase,
    required this.folderService,
  }) : super(CloudInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<ToggleEventStatus>(_onToggleEventStatus);
    on<ToggleEventSync>(_onToggleEventSync);
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
          return e.copyWith(isActive: event.isActive);
        }
        return e;
      }).toList();

      emit(CloudLoaded(events: updatedEvents));
    }
  }

  Future<void> _onToggleEventSync(
    ToggleEventSync event,
    Emitter<CloudState> emit,
  ) async {
    final currentState = state;
    if (currentState is CloudLoaded) {
      // Emit loading state for this specific event
      emit(
        EventToggling(
          events: currentState.events,
          togglingEventId: event.eventId,
        ),
      );

      try {
        // Create or delete folder based on sync status
        if (event.isSynced) {
          print('Creating folder for event: ${event.eventName}');
          final folder = await folderService.createEventFolder(event.eventName);
          print('Folder created successfully at: ${folder.path}');

          // Verify folder exists
          final exists = await folder.exists();
          print('Folder exists verification: $exists');

          if (!exists) {
            throw Exception('Folder was not created successfully');
          }
        } else {
          print('Deleting folder for event: ${event.eventName}');
          await folderService.deleteEventFolder(event.eventName);
          print('Folder deleted successfully');
        }

        // Update the event's sync status AFTER successful folder operation
        final updatedEvents = currentState.events.map((e) {
          if (e.id == event.eventId) {
            print(
              'Updating event ${e.eventName} sync status to: ${event.isSynced}',
            );
            return e.copyWith(isSynced: event.isSynced);
          }
          return e;
        }).toList();

        print('Emitting updated state with ${updatedEvents.length} events');
        emit(CloudLoaded(events: updatedEvents));
      } catch (e) {
        print('Error toggling sync: $e');
        // If folder creation/deletion fails, revert to previous state
        emit(
          CloudError(
            message:
                'Failed to ${event.isSynced ? "create" : "delete"} folder: ${e.toString()}',
          ),
        );
        // Wait a bit then restore previous state
        await Future.delayed(const Duration(milliseconds: 500));
        emit(currentState);
      }
    }
  }
}
