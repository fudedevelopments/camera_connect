import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, String>> login(
    String username,
    String password,
  ) async {
    try {
      final token = await remoteDataSource.login(username, password);
      await localDataSource.cacheToken(token);
      return Right(token);
    } on ServerException catch (e) {
      return Left(AuthFailure(message: e.message, details: e.details));
    } catch (e) {
      return Left(AuthFailure(message: 'Login Failed', details: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final token = await localDataSource.getToken();
      if (token != null && token.isNotEmpty) {
        return const Right(true);
      } else {
        return const Right(false);
      }
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearToken();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Logout Failed', details: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null || token.isEmpty) {
        return Left(
          AuthFailure(message: 'Not authenticated', details: 'No token found'),
        );
      }

      final profileModel = await remoteDataSource.getProfile(token);
      return Right(profileModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, details: e.details));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, details: e.details));
    } on ServerException catch (e) {
      return Left(AuthFailure(message: e.message, details: e.details));
    } catch (e) {
      return Left(
        AuthFailure(message: 'Failed to fetch profile', details: e.toString()),
      );
    }
  }
}
