import 'package:dio/dio.dart';
import '../../../../core/configs/api_config.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<String> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> login(String username, String password) async {
    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        // Assuming the token is in the response body, e.g., { "token": "..." }
        // or just the body itself if it's a string.
        // Adjust based on actual API response structure.
        // The user said: "response: { token: "jwt_token" }"
        return response.data['token'];
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(details: e.toString());
    }
  }
}
