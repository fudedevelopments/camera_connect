import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

/// Service for uploading photos to cloud using background_downloader
class PhotoUploadService {
  final Dio _dio;

  PhotoUploadService({required Dio dio}) : _dio = dio;

  /// Upload a photo to the presigned URL
  Future<bool> uploadPhoto({
    required File photoFile,
    required String uploadUrl,
    required String contentType,
  }) async {
    try {
      print('📤 Starting upload: ${path.basename(photoFile.path)}');

      // Read file as bytes
      final fileBytes = await photoFile.readAsBytes();

      // Upload to presigned URL using PUT request
      final response = await _dio.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': fileBytes.length.toString(),
          },
          validateStatus: (status) => status! < 500,
        ),
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print(
            '📊 Upload progress: $progress% (${path.basename(photoFile.path)})',
          );
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Upload successful: ${path.basename(photoFile.path)}');
        return true;
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return false;
    }
  }

  /// Upload a photo using background_downloader for reliability
  Future<bool> uploadPhotoBackground({
    required File photoFile,
    required String uploadUrl,
    required String contentType,
    required String taskId,
  }) async {
    try {
      print('📤 Starting background upload: ${path.basename(photoFile.path)}');

      // Create upload task
      final uploadTask = UploadTask(
        taskId: taskId,
        url: uploadUrl,
        filename: path.basename(photoFile.path),
        baseDirectory: BaseDirectory.root,
        directory: path.dirname(photoFile.path),
        post: 'PUT', // Use PUT for S3 presigned URLs
        headers: {'Content-Type': contentType},
        updates: Updates.statusAndProgress,
      );

      // Enqueue the task
      final successful = await FileDownloader().enqueue(uploadTask);

      if (successful) {
        print('✅ Upload task enqueued: ${path.basename(photoFile.path)}');
        return true;
      } else {
        print('❌ Failed to enqueue upload task');
        return false;
      }
    } catch (e) {
      print('❌ Background upload error: $e');
      return false;
    }
  }

  /// Get content type from file extension
  String getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Initialize background downloader
  Future<void> initialize() async {
    // FileDownloader is already configured by default, no initialization needed
    print('✅ PhotoUploadService initialized');
  }

  /// Configure upload callbacks
  void configureCallbacks({
    void Function(Task task)? onComplete,
    void Function(Task task, double progress)? onProgress,
    void Function(Task task)? onError,
  }) {
    FileDownloader().updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          if (update.status == TaskStatus.complete) {
            print('✅ Upload completed: ${update.task.taskId}');
            onComplete?.call(update.task);
          } else if (update.status == TaskStatus.failed) {
            print('❌ Upload failed: ${update.task.taskId}');
            onError?.call(update.task);
          }
          break;
        case TaskProgressUpdate():
          print(
            '📊 Upload progress: ${(update.progress * 100).toStringAsFixed(1)}%',
          );
          onProgress?.call(update.task, update.progress);
          break;
      }
    });
  }
}
