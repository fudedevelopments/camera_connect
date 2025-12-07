import 'package:dio/dio.dart';
import '../../../../core/configs/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/event_model.dart';
import '../models/upload_url_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents();
  Future<void> toggleEventActive(String eventId, bool isActive);
  Future<UploadUrlModel> getUploadUrl({
    required String eventId,
    required String photoName,
    required String contentType,
  });
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final Dio dio;
  final SecureStorageService secureStorage;

  EventRemoteDataSourceImpl({required this.dio, required this.secureStorage});

  @override
  Future<List<EventModel>> getEvents() async {
    try {
      final response = await dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          final success = data['success'] as bool? ?? false;

          if (success && data.containsKey('data')) {
            final eventsList = data['data'] as List<dynamic>;

            return eventsList
                .map(
                  (eventJson) =>
                      EventModel.fromJson(eventJson as Map<String, dynamic>),
                )
                .toList();
          } else {
            throw ServerException(
              message: 'Failed to fetch events',
              details: 'Status code: ${response.statusCode}',
            );
          }
        } else {
          throw ServerException(
            message: 'Invalid response format',
            details: 'Status code: ${response.statusCode}',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to load events',
          details: 'Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        details: 'Status code: ${e.response?.statusCode ?? 500}',
      );
    } catch (e) {
      throw ServerException(
        message: 'An unexpected error occurred',
        details: e.toString(),
      );
    }
  }

  @override
  Future<void> toggleEventActive(String eventId, bool isActive) async {
    try {
      final response = await dio.patch(
        '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId',
        data: {'is_active': isActive},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to toggle event status',
          details: 'Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        details: 'Status code: ${e.response?.statusCode ?? 500}',
      );
    }
  }

  @override
  Future<UploadUrlModel> getUploadUrl({
    required String eventId,
    required String photoName,
    required String contentType,
  }) async {
    try {
      // Get the token from secure storage
      final token = await secureStorage.getJwtToken();
      if (token == null) {
        throw ServerException(
          message: 'Authentication required',
          details: 'No token found',
        );
      }

      final response = await dio.post(
        '${ApiConfig.baseUrl}/event-photos/upload-url',
        data: {
          'event_id': eventId,
          'photo_name': photoName,
          'content_type': contentType,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          final success = data['success'] as bool? ?? false;

          if (success && data.containsKey('data')) {
            return UploadUrlModel.fromJson(
              data['data'] as Map<String, dynamic>,
            );
          } else {
            throw ServerException(
              message: 'Failed to get upload URL',
              details: 'Status code: ${response.statusCode}',
            );
          }
        } else {
          throw ServerException(
            message: 'Invalid response format',
            details: 'Status code: ${response.statusCode}',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to get upload URL',
          details: 'Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        details: 'Status code: ${e.response?.statusCode ?? 500}',
      );
    } catch (e) {
      throw ServerException(
        message: 'An unexpected error occurred',
        details: e.toString(),
      );
    }
  }
}
