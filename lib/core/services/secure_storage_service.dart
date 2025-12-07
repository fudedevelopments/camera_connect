import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage operations, primarily for JWT token management
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _jwtTokenKey = 'jwt_token';
  static const String _folderPathKey = 'event_folder_path';

  /// Store JWT token securely
  Future<void> saveJwtToken(String token) async {
    await _secureStorage.write(key: _jwtTokenKey, value: token);
  }

  /// Retrieve stored JWT token
  Future<String?> getJwtToken() async {
    return await _secureStorage.read(key: _jwtTokenKey);
  }

  /// Delete JWT token (used for logout)
  Future<void> deleteJwtToken() async {
    await _secureStorage.delete(key: _jwtTokenKey);
  }

  /// Store custom folder path
  Future<void> saveFolderPath(String path) async {
    await _secureStorage.write(key: _folderPathKey, value: path);
  }

  /// Retrieve custom folder path
  Future<String?> getFolderPath() async {
    return await _secureStorage.read(key: _folderPathKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
