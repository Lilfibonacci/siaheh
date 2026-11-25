import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/category_rule.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class GetCategoryRulesUseCase implements UseCase<List<CategoryRule>, NoParams> {
  const GetCategoryRulesUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, List<CategoryRule>>> call(NoParams params) =>
      _repository.getCategoryRules();
}
