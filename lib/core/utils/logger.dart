import 'package:flutter/foundation.dart';

/// Simple logger utility
class Logger {
  static void log(String message, {String tag = 'App'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void error(String message, {String tag = 'App', Object? error}) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) {
        debugPrint('[$tag] Error details: $error');
      }
    }
  }

  static void info(String message, {String tag = 'App'}) {
    log(message, tag: tag);
  }

  static void warning(String message, {String tag = 'App'}) {
    if (kDebugMode) {
      debugPrint('[$tag] WARNING: $message');
    }
  }
}
