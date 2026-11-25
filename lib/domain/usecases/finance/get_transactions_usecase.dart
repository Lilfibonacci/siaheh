import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class GetTransactionsUseCase implements UseCase<List<BankTransaction>, NoParams> {
  const GetTransactionsUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, List<BankTransaction>>> call(NoParams params) =>
      _repository.getTransactions();
}
