import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'secure_storage_service.dart';

/// Service for managing event folders
class FolderService {
  final SecureStorageService _storageService;

  FolderService({required SecureStorageService storageService})
    : _storageService = storageService;

  /// Get the base directory for event folders
  Future<Directory> getEventsDirectory() async {
    // Check if custom path is set
    final customPath = await _storageService.getFolderPath();

    Directory eventsDir;
    if (customPath != null && customPath.isNotEmpty) {
      // Use custom path
      eventsDir = Directory(customPath);
    } else {
      // Use default path in external storage (Documents/camera_connect)
      Directory? externalDir;
      if (Platform.isAndroid) {
        externalDir = Directory('/storage/emulated/0/Documents');
      } else {
        externalDir = await getApplicationDocumentsDirectory();
      }
      eventsDir = Directory(path.join(externalDir.path, 'camera_connect'));
    }

    if (!await eventsDir.exists()) {
      await eventsDir.create(recursive: true);
    }

    return eventsDir;
  }

  /// Create a folder for an event
  Future<Directory> createEventFolder(String eventName) async {
    try {
      // Check and request permission if needed
      await _ensureStoragePermission();

      final eventsDir = await getEventsDirectory();

      // Sanitize event name for folder name
      final sanitizedName = _sanitizeFolderName(eventName);
      final eventDir = Directory(path.join(eventsDir.path, sanitizedName));

      if (!await eventDir.exists()) {
        await eventDir.create(recursive: true);
      }

      return eventDir;
    } catch (e) {
      throw Exception('Failed to create event folder: $e');
    }
  }

  /// Delete an event folder
  Future<void> deleteEventFolder(String eventName) async {
    try {
      final eventsDir = await getEventsDirectory();
      final sanitizedName = _sanitizeFolderName(eventName);
      final eventDir = Directory(path.join(eventsDir.path, sanitizedName));

      if (await eventDir.exists()) {
        await eventDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to delete event folder: $e');
    }
  }

  /// Check if an event folder exists
  Future<bool> eventFolderExists(String eventName) async {
    try {
      final eventsDir = await getEventsDirectory();
      final sanitizedName = _sanitizeFolderName(eventName);
      final eventDir = Directory(path.join(eventsDir.path, sanitizedName));

      return await eventDir.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get the path to an event folder
  Future<String> getEventFolderPath(String eventName) async {
    final eventsDir = await getEventsDirectory();
    final sanitizedName = _sanitizeFolderName(eventName);
    return path.join(eventsDir.path, sanitizedName);
  }

  /// Get the current base folder path
  Future<String> getCurrentBasePath() async {
    final customPath = await _storageService.getFolderPath();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    Directory externalDir;
    if (Platform.isAndroid) {
      externalDir = Directory('/storage/emulated/0/Documents');
    } else {
      externalDir = await getApplicationDocumentsDirectory();
    }
    return path.join(externalDir.path, 'camera_connect');
  }

  /// Initialize default folder on app first launch
  Future<void> initializeDefaultFolder() async {
    try {
      await _ensureStoragePermission();
      final eventsDir = await getEventsDirectory();
      if (!await eventsDir.exists()) {
        await eventsDir.create(recursive: true);
      }
    } catch (e) {
      // Silently fail - folder will be created when needed
    }
  }

  /// Set custom folder path
  Future<void> setCustomFolderPath(String customPath) async {
    await _storageService.saveFolderPath(customPath);
  }

  /// Sanitize folder name by removing invalid characters
  String _sanitizeFolderName(String name) {
    // Remove invalid characters for file systems
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  /// Ensure storage permission is granted
  Future<void> _ensureStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // For Android 11+ (API 30+), also request manage external storage
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }
  }
}
