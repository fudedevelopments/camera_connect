/// Upload status for a photo
class UploadStatus {
  final String fileName;
  final String filePath;
  final String eventId;
  final UploadState state;
  final double progress;
  final DateTime detectedAt;
  final String? errorMessage;

  const UploadStatus({
    required this.fileName,
    required this.filePath,
    required this.eventId,
    required this.state,
    this.progress = 0.0,
    required this.detectedAt,
    this.errorMessage,
  });

  UploadStatus copyWith({
    String? fileName,
    String? filePath,
    String? eventId,
    UploadState? state,
    double? progress,
    DateTime? detectedAt,
    String? errorMessage,
  }) {
    return UploadStatus(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      eventId: eventId ?? this.eventId,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      detectedAt: detectedAt ?? this.detectedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum UploadState { detected, gettingUrl, uploading, completed, failed }
