import 'package:dio/dio.dart';
import '../../../../core/configs/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_profile_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> login(String username, String password);
  Future<UserProfileModel> getProfile(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> login(String username, String password) async {
    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
        data: {'email': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response formats
        if (data is Map<String, dynamic>) {
          if (data.containsKey('token')) {
            return data['token'] as String;
          } else {
            throw AuthException(
              message: 'Invalid response format',
              details: 'Token not found in response',
            );
          }
        } else if (data is String) {
          return data;
        } else {
          throw AuthException(
            message: 'Invalid response format',
            details: 'Unexpected response type: ${data.runtimeType}',
          );
        }
      } else {
        throw AuthException(
          message: 'Login failed',
          details: 'Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException(
          message: 'Invalid username or password',
          details: e.response?.data.toString(),
        );
      } else if (e.response?.statusCode == 404) {
        throw AuthException(
          message: 'Login endpoint not found',
          details: 'URL: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          message: 'Connection timeout',
          details: 'Please check your internet connection',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: 'Cannot connect to server',
          details: 'Make sure the server is running at ${ApiConfig.baseUrl}',
        );
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Server error occurred',
          details: e.message,
        );
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(
        message: 'Unexpected error occurred',
        details: e.toString(),
      );
    }
  }

  @override
  Future<UserProfileModel> getProfile(String token) async {
    try {
      final response = await dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true) {
            if (data.containsKey('data')) {
              return UserProfileModel.fromJson(
                data['data'] as Map<String, dynamic>,
              );
            } else {
              throw AuthException(
                message: 'Invalid response format',
                details: 'Data not found in response',
              );
            }
          } else {
            throw AuthException(
              message: 'Profile fetch failed',
              details: data['message'] ?? 'Unknown error',
            );
          }
        } else {
          throw AuthException(
            message: 'Invalid response format',
            details: 'Unexpected response type: ${data.runtimeType}',
          );
        }
      } else {
        throw AuthException(
          message: 'Profile fetch failed',
          details: 'Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException(
          message: 'Unauthorized - Invalid or expired token',
          details: e.response?.data.toString(),
        );
      } else if (e.response?.statusCode == 404) {
        throw AuthException(
          message: 'Profile endpoint not found',
          details: 'URL: ${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          message: 'Connection timeout',
          details: 'Please check your internet connection',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: 'Cannot connect to server',
          details: 'Make sure the server is running at ${ApiConfig.baseUrl}',
        );
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Server error occurred',
          details: e.message,
        );
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(
        message: 'Unexpected error occurred',
        details: e.toString(),
      );
    }
  }
}
