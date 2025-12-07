import 'package:dio/dio.dart';
import '../../../../core/configs/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents();
  Future<void> toggleEventActive(String eventId, bool isActive);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final Dio dio;

  EventRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<EventModel>> getEvents() async {
    try {
      print('🔵 Get Events API Request:');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}');

      final response = await dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}',
      );

      print('🟢 Get Events API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          final success = data['success'] as bool? ?? false;

          if (success && data.containsKey('data')) {
            final eventsList = data['data'] as List<dynamic>;
            print('✅ Events retrieved: ${eventsList.length} events');

            return eventsList
                .map(
                  (eventJson) =>
                      EventModel.fromJson(eventJson as Map<String, dynamic>),
                )
                .toList();
          } else {
            print('❌ Success flag is false or data key not found');
            throw ServerException(
              message: 'Failed to fetch events',
              details: 'Status code: ${response.statusCode}',
            );
          }
        } else {
          print('❌ Response is not a Map');
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
      print('❌ Dio Error: ${e.message}');
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        details: 'Status code: ${e.response?.statusCode ?? 500}',
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      throw ServerException(
        message: 'An unexpected error occurred',
        details: e.toString(),
      );
    }
  }

  @override
  Future<void> toggleEventActive(String eventId, bool isActive) async {
    try {
      print('🔵 Toggle Event Active API Request:');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId');
      print('Data: {is_active: $isActive}');

      final response = await dio.patch(
        '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId',
        data: {'is_active': isActive},
      );

      print('🟢 Toggle Event Active API Response:');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to toggle event status',
          details: 'Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Dio Error: ${e.message}');
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        details: 'Status code: ${e.response?.statusCode ?? 500}',
      );
    }
  }
}
