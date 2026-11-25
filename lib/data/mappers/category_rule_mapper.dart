import 'package:siaheh/data/dtos/category_rule_dto.dart';
import 'package:siaheh/domain/entities/category_rule.dart';

class CategoryRuleMapper {
  const CategoryRuleMapper._();

  static CategoryRule toEntity(CategoryRuleDto dto) => CategoryRule(
    pattern: dto.pattern,
    categoryId: dto.categoryId,
    preferredTitle: dto.preferredTitle,
  );

  static CategoryRuleDto toDto(CategoryRule entity) => CategoryRuleDto(
    pattern: entity.pattern,
    categoryId: entity.categoryId,
    preferredTitle: entity.preferredTitle,
  );
}
