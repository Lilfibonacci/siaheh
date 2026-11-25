import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class RequestSmsPermissionUseCase implements PlainUseCase<bool, NoParams> {
  const RequestSmsPermissionUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<bool> call(NoParams params) => _repository.requestSmsPermission();
}
