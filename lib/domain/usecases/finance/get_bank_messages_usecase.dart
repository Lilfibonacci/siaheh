import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class GetBankMessagesUseCase
    implements UseCase<List<BankSmsMessage>, NoParams> {
  const GetBankMessagesUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, List<BankSmsMessage>>> call(NoParams params) =>
      _repository.getBankMessages();
}
