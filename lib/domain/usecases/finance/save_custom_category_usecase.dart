import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/custom_category.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class SaveCustomCategoryUseCase implements UseCase<Unit, CustomCategory> {
  const SaveCustomCategoryUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CustomCategory params) =>
      _repository.saveCustomCategory(params);
}
