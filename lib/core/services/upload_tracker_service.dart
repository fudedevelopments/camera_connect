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
    print('✅ Upload tracker initialized');
  }

  /// Check if a file has been uploaded for an event
  bool isFileUploaded(String eventId, String fileName) {
    if (_uploadedFilesBox == null) {
      print('⚠️ Upload tracker not initialized');
      return false;
    }

    final uploadedFiles = _uploadedFilesBox!.get(eventId);
    if (uploadedFiles == null) {
      return false;
    }

    return uploadedFiles.contains(fileName);
  }

  /// Mark a file as uploaded for an event
  Future<void> markFileAsUploaded(String eventId, String fileName) async {
    if (_uploadedFilesBox == null) {
      print('⚠️ Upload tracker not initialized');
      return;
    }

    final uploadedFiles = _uploadedFilesBox!.get(eventId) ?? <String>[];

    if (!uploadedFiles.contains(fileName)) {
      uploadedFiles.add(fileName);
      await _uploadedFilesBox!.put(eventId, uploadedFiles);
      print('✅ Marked as uploaded: $fileName for event: $eventId');
    }
  }

  /// Get all uploaded files for an event
  List<String> getUploadedFiles(String eventId) {
    if (_uploadedFilesBox == null) {
      print('⚠️ Upload tracker not initialized');
      return [];
    }

    return _uploadedFilesBox!.get(eventId) ?? [];
  }

  /// Clear uploaded files tracking for an event
  Future<void> clearEventTracking(String eventId) async {
    if (_uploadedFilesBox == null) {
      print('⚠️ Upload tracker not initialized');
      return;
    }

    await _uploadedFilesBox!.delete(eventId);
    print('🗑️ Cleared upload tracking for event: $eventId');
  }

  /// Clear all uploaded files tracking
  Future<void> clearAllTracking() async {
    if (_uploadedFilesBox == null) {
      print('⚠️ Upload tracker not initialized');
      return;
    }

    await _uploadedFilesBox!.clear();
    print('🗑️ Cleared all upload tracking');
  }

  /// Get count of uploaded files for an event
  int getUploadedCount(String eventId) {
    if (_uploadedFilesBox == null) {
      print('⚠️ Upload tracker not initialized');
      return 0;
    }

    final uploadedFiles = _uploadedFilesBox!.get(eventId);
    return uploadedFiles?.length ?? 0;
  }

  /// Close the Hive box
  Future<void> dispose() async {
    await _uploadedFilesBox?.close();
    print('📦 Upload tracker closed');
  }
}
