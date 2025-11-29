import 'package:flutter/material.dart';

/// Log entry model for debug logging
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? details;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: map['level'] ?? 'INFO',
      message: map['message'] ?? '',
      details: map['details'],
    );
  }

  factory LogEntry.info(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: 'INFO',
      message: message,
      details: details,
    );
  }

  factory LogEntry.error(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: 'ERROR',
      message: message,
      details: details,
    );
  }

  factory LogEntry.success(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: 'SUCCESS',
      message: message,
      details: details,
    );
  }

  factory LogEntry.warning(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: 'WARNING',
      message: message,
      details: details,
    );
  }

  factory LogEntry.debug(String message, [String? details]) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: 'DEBUG',
      message: message,
      details: details,
    );
  }

  Color get color {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'SUCCESS':
        return Colors.green;
      case 'DEBUG':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Icons.error;
      case 'WARNING':
        return Icons.warning;
      case 'SUCCESS':
        return Icons.check_circle;
      case 'DEBUG':
        return Icons.bug_report;
      default:
        return Icons.info;
    }
  }

  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  @override
  String toString() {
    return '[$formattedTimestamp] [$level] $message${details != null ? '\n  $details' : ''}';
  }
}
