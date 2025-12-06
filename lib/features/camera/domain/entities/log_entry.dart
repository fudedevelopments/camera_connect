import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Log entry entity for debug logging
class LogEntry extends Equatable {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? details;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });

  factory LogEntry.info(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      message: message,
      details: details,
    );
  }

  factory LogEntry.error(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      message: message,
      details: details,
    );
  }

  factory LogEntry.success(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.success,
      message: message,
      details: details,
    );
  }

  factory LogEntry.warning(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.warning,
      message: message,
      details: details,
    );
  }

  Color get color {
    switch (level) {
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (level) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.success:
        return Icons.check_circle_outline;
      case LogLevel.warning:
        return Icons.warning_outlined;
    }
  }

  @override
  List<Object?> get props => [timestamp, level, message, details];
}

/// Log level enum
enum LogLevel {
  info,
  error,
  success,
  warning;

  String get name {
    switch (this) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.success:
        return 'SUCCESS';
      case LogLevel.warning:
        return 'WARNING';
    }
  }
}
