import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base UseCase interface
/// [Type] is the return type
/// [Params] is the parameter type
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// UseCase with no parameters
class NoParams {}
