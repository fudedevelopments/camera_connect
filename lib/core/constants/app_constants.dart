/// Application-wide constants
class AppConstants {
  // PTP/IP Constants
  static const String ptpMethodChannel = 'com.tanzo.camera/ptp';
  static const String ptpEventChannel = 'com.tanzo.camera/ptp_events';
  static const int defaultPtpPort = 15740;

  // Log levels
  static const String logLevelInfo = 'INFO';
  static const String logLevelError = 'ERROR';
  static const String logLevelSuccess = 'SUCCESS';
  static const String logLevelWarning = 'WARNING';

  // Event types
  static const String eventTypeLog = 'log';
  static const String eventTypeStatus = 'status';
  static const String eventTypeImages = 'images';
  static const String eventTypeProgress = 'progress';
}
