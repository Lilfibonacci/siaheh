import 'package:equatable/equatable.dart';

/// Base type for every error that crosses the domain boundary.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Local storage (Hive) read/write problem.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطا در دسترسی به حافظه محلی']);
}

/// The user denied (or revoked) a required permission.
final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'دسترسی لازم داده نشده است']);
}

/// An SMS could not be understood by any registered bank parser.
final class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'پیامک قابل تفسیر نیست']);
}

/// Requested entity does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'مورد یافت نشد']);
}

/// Anything unexpected.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'خطای ناشناخته']);
}
