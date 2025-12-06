/// API Configuration for backend connection
class ApiConfig {
  /// Base URL for the backend server
  static const String baseUrl = 'http://127.0.0.1:8787';

  /// Upload image endpoint path
  static const String uploadImagePath = '/upload-url';

  /// Full upload image URL
  static String get uploadImageUrl => '$baseUrl$uploadImagePath';
}
