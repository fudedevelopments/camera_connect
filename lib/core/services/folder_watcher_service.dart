import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Service for watching folder for new images
class FolderWatcherService {
  StreamController<File>? _newFileController;
  Timer? _pollingTimer;
  Set<String> _knownFiles = {};
  String? _watchedFolderPath;

  /// Start watching a folder for new image files
  Stream<File> watchFolder(String folderPath) {
    stopWatching();

    _watchedFolderPath = folderPath;
    _newFileController = StreamController<File>.broadcast();
    _knownFiles.clear();

    // Initialize known files
    _scanFolder(folderPath, isInitial: true);

    // Poll every 2 seconds for new files
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _scanFolder(folderPath);
    });

    return _newFileController!.stream;
  }

  /// Stop watching the folder
  void stopWatching() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _newFileController?.close();
    _newFileController = null;
    _knownFiles.clear();
    _watchedFolderPath = null;
  }

  /// Scan folder for new image files
  void _scanFolder(String folderPath, {bool isInitial = false}) {
    try {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) return;

      final files = dir.listSync();
      for (final entity in files) {
        if (entity is File && _isImageFile(entity.path)) {
          final filePath = entity.path;

          // If this is a new file (not in known files)
          if (!_knownFiles.contains(filePath)) {
            _knownFiles.add(filePath);

            // Don't emit files on initial scan
            if (!isInitial) {
              print('📸 New image detected: ${path.basename(filePath)}');
              _newFileController?.add(entity);
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error scanning folder: $e');
    }
  }

  /// Check if file is an image based on extension
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
    ].contains(extension);
  }

  /// Get the currently watched folder path
  String? get watchedFolderPath => _watchedFolderPath;

  /// Check if currently watching a folder
  bool get isWatching => _pollingTimer != null && _pollingTimer!.isActive;

  /// Dispose of resources
  void dispose() {
    stopWatching();
  }
}
