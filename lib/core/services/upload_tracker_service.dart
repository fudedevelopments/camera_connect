import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

/// Service to track uploaded files using Hive database
@singleton
class UploadTrackerService {
  static const String _boxName = 'uploaded_files';
  Box<List<String>>? _uploadedFilesBox;

  /// Initialize Hive and open the box
  Future<void> initialize() async {
    await Hive.initFlutter();
    _uploadedFilesBox = await Hive.openBox<List<String>>(_boxName);
  }

  /// Check if a file has been uploaded for an event
  bool isFileUploaded(String eventId, String fileName) {
    if (_uploadedFilesBox == null) {
      return false;
    }

    final uploadedFiles = _uploadedFilesBox!.get(eventId);
    if (uploadedFiles == null || uploadedFiles.isEmpty) {
      return false;
    }

    final isUploaded = uploadedFiles.contains(fileName);
    return isUploaded;
  }

  /// Mark a file as uploaded for an event
  Future<void> markFileAsUploaded(String eventId, String fileName) async {
    if (_uploadedFilesBox == null) {
      return;
    }

    // Get current list and create a mutable copy
    final currentList = _uploadedFilesBox!.get(eventId);
    final uploadedFiles = currentList != null
        ? List<String>.from(currentList)
        : <String>[];

    if (!uploadedFiles.contains(fileName)) {
      uploadedFiles.add(fileName);
      await _uploadedFilesBox!.put(eventId, uploadedFiles);
    }
  }

  /// Get all uploaded files for an event
  List<String> getUploadedFiles(String eventId) {
    if (_uploadedFilesBox == null) {
      return [];
    }

    return _uploadedFilesBox!.get(eventId) ?? [];
  }

  /// Clear uploaded files tracking for an event
  Future<void> clearEventTracking(String eventId) async {
    if (_uploadedFilesBox == null) {
      return;
    }

    await _uploadedFilesBox!.delete(eventId);
  }

  /// Clear all uploaded files tracking
  Future<void> clearAllTracking() async {
    if (_uploadedFilesBox == null) {
      return;
    }

    await _uploadedFilesBox!.clear();
  }

  /// Get count of uploaded files for an event
  int getUploadedCount(String eventId) {
    if (_uploadedFilesBox == null) {
      return 0;
    }

    final uploadedFiles = _uploadedFilesBox!.get(eventId);
    return uploadedFiles?.length ?? 0;
  }

  /// Close the Hive box
  Future<void> dispose() async {
    await _uploadedFilesBox?.close();
  }
}
