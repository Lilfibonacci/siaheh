import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';

/// Contract for an asynchronous use case returning [Either<Failure, Output>].
abstract interface class UseCase<Output, Params> {
  Future<Either<Failure, Output>> call(Params params);
}

/// Contract for an asynchronous use case returning [Output] directly.
abstract interface class PlainUseCase<Output, Params> {
  Future<Output> call(Params params);
}

/// Contract for a synchronous use case returning [Output] directly.
abstract interface class SyncUseCase<Output, Params> {
  Output call(Params params);
}

/// Contract for a use case that exposes a stream of results.
abstract interface class StreamUseCase<Output, Params> {
  Stream<Output> call(Params params);
}

/// Used when a use case takes no input parameters.
final class NoParams {
  const NoParams();
}
