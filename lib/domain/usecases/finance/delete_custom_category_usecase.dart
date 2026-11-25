import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class DeleteCustomCategoryUseCase implements UseCase<Unit, String> {
  const DeleteCustomCategoryUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.deleteCustomCategory(params);
}
