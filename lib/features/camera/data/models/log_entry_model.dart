import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/log_entry.dart' as domain;

/// Log entry model for data layer
class LogEntryModel extends domain.LogEntry {
  const LogEntryModel({
    required super.timestamp,
    required super.level,
    required super.message,
    super.details,
  });

  factory LogEntryModel.fromMap(Map<String, dynamic> map) {
    return LogEntryModel(
      timestamp: DateTime.now(),
      level: _parseLogLevel(map['level'] ?? AppConstants.logLevelInfo),
      message: map['message'] ?? '',
      details: map['details'],
    );
  }

  static domain.LogLevel _parseLogLevel(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return domain.LogLevel.error;
      case 'SUCCESS':
        return domain.LogLevel.success;
      case 'WARNING':
        return domain.LogLevel.warning;
      case 'INFO':
      default:
        return domain.LogLevel.info;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'details': details,
    };
  }

  /// Convert to domain entity
  domain.LogEntry toEntity() {
    return domain.LogEntry(
      timestamp: timestamp,
      level: level,
      message: message,
      details: details,
    );
  }
}
