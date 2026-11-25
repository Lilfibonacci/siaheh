import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class WatchIncomingMessagesUseCase
    implements StreamUseCase<BankSmsMessage, NoParams> {
  const WatchIncomingMessagesUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Stream<BankSmsMessage> call(NoParams params) => _repository.incomingMessages;
}
