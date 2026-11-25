import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class GetSendersUseCase implements UseCase<List<SmsSender>, NoParams> {
  const GetSendersUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, List<SmsSender>>> call(NoParams params) =>
      _repository.getSenders();
}
