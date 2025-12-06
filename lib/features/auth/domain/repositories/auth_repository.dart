import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> login(String username, String password);
  Future<Either<Failure, bool>> checkAuthStatus();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserProfile>> getProfile();
}
