/// Simple logger utility
class Logger {
  static void log(String message, {String tag = 'App'}) {}

  static void error(String message, {String tag = 'App', Object? error}) {}

  static void info(String message, {String tag = 'App'}) {
    log(message, tag: tag);
  }

  static void warning(String message, {String tag = 'App'}) {}
}
