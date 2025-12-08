import 'dart:io';
import 'dart:developer' as developer;
import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'image_compression_service.dart';

/// Service for uploading photos to cloud using background_downloader
class PhotoUploadService {
  final Dio _dio;
  final ImageCompressionService _compressionService;

  PhotoUploadService({
    required Dio dio,
    required ImageCompressionService compressionService,
  }) : _dio = dio,
       _compressionService = compressionService;

  /// Upload a photo to the presigned URL
  /// Automatically compresses image if needed before upload
  Future<File> prepareImageForUpload(File photoFile) async {
    return await _compressionService.compressImageIfNeeded(photoFile);
  }

  /// Upload a photo to the presigned URL
  Future<bool> uploadPhoto({
    required File photoFile,
    required String uploadUrl,
    required String contentType,
  }) async {
    try {
      final fileName = path.basename(photoFile.path);
      developer.log('📤 Starting Photo Upload: $fileName', name: 'PhotoUpload');

      // Compress image if needed
      final processedFile = await prepareImageForUpload(photoFile);

      // Read file as bytes
      final fileBytes = await processedFile.readAsBytes();
      final sizeStr = _compressionService.getFileSizeString(fileBytes.length);

      developer.log('  Uploading ${sizeStr}...', name: 'PhotoUpload');

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
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        developer.log(
          '✅ Upload Successful (Status: ${response.statusCode})',
          name: 'PhotoUpload',
        );
        return true;
      } else {
        developer.log(
          '❌ Upload Failed (Status: ${response.statusCode})',
          name: 'PhotoUpload',
        );
        return false;
      }
    } catch (e) {
      developer.log('❌ Upload Error: $e', name: 'PhotoUpload', error: e);
      return false;
    }
  }

  /// Upload a photo using background_downloader for reliability
  /// Automatically compresses image if needed before upload
  Future<bool> uploadPhotoBackground({
    required File photoFile,
    required String uploadUrl,
    required String contentType,
    required String taskId,
  }) async {
    try {
      final fileName = path.basename(photoFile.path);
      developer.log(
        '📤 Starting Background Upload: $fileName',
        name: 'PhotoUpload',
      );

      // Compress image if needed
      final processedFile = await prepareImageForUpload(photoFile);
      final fileSize = await processedFile.length();
      final sizeStr = _compressionService.getFileSizeString(fileSize);

      developer.log(
        '  Enqueueing upload task (${sizeStr})...',
        name: 'PhotoUpload',
      );

      // Create upload task
      final uploadTask = UploadTask(
        taskId: taskId,
        url: uploadUrl,
        filename: path.basename(processedFile.path),
        baseDirectory: BaseDirectory.root,
        directory: path.dirname(processedFile.path),
        post: 'PUT', // Use PUT for S3 presigned URLs
        headers: {'Content-Type': contentType},
        updates: Updates.statusAndProgress,
      );

      // Enqueue the task
      final successful = await FileDownloader().enqueue(uploadTask);

      if (successful) {
        developer.log(
          '✅ Upload task enqueued successfully',
          name: 'PhotoUpload',
        );
        return true;
      } else {
        developer.log('❌ Failed to enqueue upload task', name: 'PhotoUpload');
        return false;
      }
    } catch (e) {
      developer.log(
        '❌ Background Upload Error: $e',
        name: 'PhotoUpload',
        error: e,
      );
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
            onComplete?.call(update.task);
          } else if (update.status == TaskStatus.failed) {
            onError?.call(update.task);
          }
          break;
        case TaskProgressUpdate():
          onProgress?.call(update.task, update.progress);
          break;
      }
    });
  }
}
