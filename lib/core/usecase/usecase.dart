import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';

/// Contract for a single application use case.
abstract interface class UseCase<Output, Params> {
  Future<Either<Failure, Output>> call(Params params);
}

/// Contract for a use case that exposes a continuous stream of results.
abstract interface class StreamUseCase<Output, Params> {
  Stream<Either<Failure, Output>> call(Params params);
}

/// Used when a use case needs no input.
final class NoParams {
  const NoParams();
}
