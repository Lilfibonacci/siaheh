import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class SaveSenderUseCase implements UseCase<Unit, SmsSender> {
  const SaveSenderUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SmsSender params) =>
      _repository.saveSender(params);
}
