import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/custom_category.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class GetCustomCategoriesUseCase
    implements UseCase<List<CustomCategory>, NoParams> {
  const GetCustomCategoriesUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, List<CustomCategory>>> call(NoParams params) =>
      _repository.getCustomCategories();
}
