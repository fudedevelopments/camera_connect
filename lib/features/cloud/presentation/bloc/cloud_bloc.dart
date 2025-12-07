import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/folder_service.dart';
import '../../../../core/services/folder_watcher_service.dart';
import '../../../../core/services/photo_upload_service.dart';
import '../../../../core/services/upload_tracker_service.dart';
import '../../domain/entities/upload_status.dart';
import '../../domain/usecases/get_events.dart';
import '../../domain/usecases/get_upload_url.dart';
import '../../domain/usecases/toggle_event_active.dart';
import 'cloud_event.dart';
import 'cloud_state.dart';

class CloudBloc extends Bloc<CloudEvent, CloudState> {
  final GetEventsUseCase getEventsUseCase;
  final ToggleEventActiveUseCase toggleEventActiveUseCase;
  final GetUploadUrl getUploadUrlUseCase;
  final FolderService folderService;
  final FolderWatcherService folderWatcherService;
  final PhotoUploadService photoUploadService;
  final UploadTrackerService uploadTrackerService;

  // Track active folder watchers by event ID
  final Map<String, StreamSubscription<File>> _activeWatchers = {};

  // Track upload statuses by event ID
  final Map<String, List<UploadStatus>> _uploadStatuses = {};

  CloudBloc({
    required this.getEventsUseCase,
    required this.toggleEventActiveUseCase,
    required this.getUploadUrlUseCase,
    required this.folderService,
    required this.folderWatcherService,
    required this.photoUploadService,
    required this.uploadTrackerService,
  }) : super(CloudInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<ToggleEventStatus>(_onToggleEventStatus);
    on<ToggleEventSync>(_onToggleEventSync);
    on<ToggleAutoUpload>(_onToggleAutoUpload);
    on<UpdateUploadStatuses>(_onUpdateUploadStatuses);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<CloudState> emit) async {
    emit(CloudLoading());
    try {
      final events = await getEventsUseCase();
      emit(CloudLoaded(events: events, uploadStatuses: _uploadStatuses));
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

      emit(
        CloudLoaded(
          events: updatedEvents,
          uploadStatuses: currentState.uploadStatuses,
        ),
      );
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
          uploadStatuses: currentState.uploadStatuses,
        ),
      );

      try {
        // Create or delete folder based on sync status
        if (event.isSynced) {
          // Check if folder already exists
          final folderExists = await folderService.eventFolderExists(
            event.eventName,
          );

          if (folderExists) {
          } else {
            final folder = await folderService.createEventFolder(
              event.eventName,
            );

            // Verify folder exists
            final exists = await folder.exists();

            if (!exists) {
              throw Exception('Folder was not created successfully');
            }
          }
        } else {
          await folderService.deleteEventFolder(event.eventName);
        }

        // Update the event's sync status AFTER successful folder operation
        final updatedEvents = currentState.events.map((e) {
          if (e.id == event.eventId) {
            return e.copyWith(isSynced: event.isSynced);
          }
          return e;
        }).toList();

        emit(
          CloudLoaded(
            events: updatedEvents,
            uploadStatuses: currentState.uploadStatuses,
          ),
        );
      } catch (e) {
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

  Future<void> _onToggleAutoUpload(
    ToggleAutoUpload event,
    Emitter<CloudState> emit,
  ) async {
    final currentState = state;
    if (currentState is CloudLoaded) {
      try {
        if (event.autoUpload) {
          // Update UI to show toggle ON immediately
          final updatedEvents = currentState.events.map((e) {
            if (e.id == event.eventId) {
              return e.copyWith(autoUpload: true);
            }
            return e;
          }).toList();

          emit(
            CloudLoaded(events: updatedEvents, uploadStatuses: _uploadStatuses),
          );

          // Start watching folder for new images
          await _startWatchingFolder(event.eventId, event.eventName);
        } else {
          // Stop watching folder
          await _stopWatchingFolder(event.eventId);

          // Update the event's auto-upload status to OFF
          final updatedEvents = currentState.events.map((e) {
            if (e.id == event.eventId) {
              return e.copyWith(autoUpload: false);
            }
            return e;
          }).toList();

          // Only clear upload statuses UI, but KEEP the uploaded files tracking
          // This ensures files won't be re-uploaded when auto-upload is turned back on
          _uploadStatuses.remove(event.eventId);

          emit(
            CloudLoaded(events: updatedEvents, uploadStatuses: _uploadStatuses),
          );
        }
      } catch (e) {
        emit(
          CloudError(message: 'Failed to toggle auto-upload: ${e.toString()}'),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateUploadStatuses(
    UpdateUploadStatuses event,
    Emitter<CloudState> emit,
  ) async {
    final currentState = state;
    if (currentState is CloudLoaded) {
      // Just refresh the state with current upload statuses
      emit(currentState.copyWith(uploadStatuses: _uploadStatuses));
    }
  }

  Future<void> _startWatchingFolder(String eventId, String eventName) async {
    // Stop any existing watcher for this event
    await _stopWatchingFolder(eventId);

    // Get folder path
    final folderPath = await folderService.getEventFolderPath(eventName);

    // Upload existing files in the folder first
    await _uploadExistingFiles(eventId, folderPath);

    // Start watching for new files
    final fileStream = folderWatcherService.watchFolder(folderPath);

    // Subscribe to new file events
    final subscription = fileStream.listen((file) async {
      await _handleNewPhoto(eventId, file);
    });

    _activeWatchers[eventId] = subscription;
  }

  Future<void> _stopWatchingFolder(String eventId) async {
    final subscription = _activeWatchers[eventId];
    if (subscription != null) {
      await subscription.cancel();
      _activeWatchers.remove(eventId);
    }
    folderWatcherService.stopWatching();
  }

  Future<void> _handleNewPhoto(String eventId, File photoFile) async {
    try {
      final fileName = path.basename(photoFile.path);

      // Check if this file was already uploaded
      if (uploadTrackerService.isFileUploaded(eventId, fileName)) {
        return;
      }

      // Add to upload statuses
      final uploadStatus = UploadStatus(
        fileName: fileName,
        filePath: photoFile.path,
        eventId: eventId,
        state: UploadState.detected,
        detectedAt: DateTime.now(),
      );

      _addUploadStatus(eventId, uploadStatus);

      // Update to getting URL state
      _updateUploadStatus(eventId, fileName, UploadState.gettingUrl);

      // Get upload URL from API
      final contentType = photoUploadService.getContentType(photoFile.path);

      final uploadUrl = await getUploadUrlUseCase(
        eventId: eventId,
        photoName: fileName,
        contentType: contentType,
      );

      // Update to uploading state
      _updateUploadStatus(eventId, fileName, UploadState.uploading);

      // Upload photo directly using Dio (presigned URLs require PUT)
      final success = await photoUploadService.uploadPhoto(
        photoFile: photoFile,
        uploadUrl: uploadUrl.uploadUrl,
        contentType: contentType,
      );

      if (success) {
        _updateUploadStatus(eventId, fileName, UploadState.completed);

        // Track this file as uploaded to prevent duplicates
        await uploadTrackerService.markFileAsUploaded(eventId, fileName);

        // Trigger state update to refresh UI
        add(const UpdateUploadStatuses());
      } else {
        _updateUploadStatus(
          eventId,
          fileName,
          UploadState.failed,
          errorMessage: 'Failed to start upload',
        );

        // Trigger state update to refresh UI
        add(const UpdateUploadStatuses());
      }
    } catch (e) {
      final fileName = path.basename(photoFile.path);
      _updateUploadStatus(
        eventId,
        fileName,
        UploadState.failed,
        errorMessage: e.toString(),
      );

      // Trigger state update to refresh UI
      add(const UpdateUploadStatuses());
    }
  }

  void _addUploadStatus(String eventId, UploadStatus status) {
    if (!_uploadStatuses.containsKey(eventId)) {
      _uploadStatuses[eventId] = [];
    }
    _uploadStatuses[eventId]!.add(status);

    // Keep only last 20 uploads per event
    if (_uploadStatuses[eventId]!.length > 20) {
      _uploadStatuses[eventId]!.removeAt(0);
    }
  }

  void _updateUploadStatus(
    String eventId,
    String fileName,
    UploadState newState, {
    double? progress,
    String? errorMessage,
  }) {
    final statuses = _uploadStatuses[eventId];
    if (statuses != null) {
      final index = statuses.indexWhere((s) => s.fileName == fileName);
      if (index != -1) {
        _uploadStatuses[eventId]![index] = statuses[index].copyWith(
          state: newState,
          progress: progress,
          errorMessage: errorMessage,
        );
      }
    }
  }

  Future<void> _uploadExistingFiles(String eventId, String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        return;
      }

      // List all files in the directory asynchronously
      final entities = await dir.list().toList();

      final imageFiles = <File>[];
      for (final entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if ([
            '.jpg',
            '.jpeg',
            '.png',
            '.gif',
            '.bmp',
            '.webp',
          ].contains(extension)) {
            imageFiles.add(entity);
          }
        }
      }

      if (imageFiles.isEmpty) {
        return;
      }

      // Upload each existing file
      for (final file in imageFiles) {
        await _handleNewPhoto(eventId, file);
        // Small delay between uploads to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {}
  }

  @override
  Future<void> close() async {
    // Clean up all active watchers
    for (final subscription in _activeWatchers.values) {
      await subscription.cancel();
    }
    _activeWatchers.clear();
    folderWatcherService.dispose();
    return super.close();
  }
}
