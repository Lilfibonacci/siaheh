import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class UpdateTransactionParams extends Equatable {
  const UpdateTransactionParams(
    this.transaction, {
    this.applyToSimilar = false,
  });

  final BankTransaction transaction;
  final bool applyToSimilar;

  @override
  List<Object?> get props => [transaction, applyToSimilar];
}

class UpdateTransactionUseCase
    implements UseCase<Unit, UpdateTransactionParams> {
  const UpdateTransactionUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdateTransactionParams params) =>
      _repository.updateTransaction(
        params.transaction,
        applyToSimilar: params.applyToSimilar,
      );
}
