import 'package:siaheh/data/dtos/custom_category_dto.dart';
import 'package:siaheh/domain/entities/custom_category.dart';

class CustomCategoryMapper {
  const CustomCategoryMapper._();

  static CustomCategory toEntity(CustomCategoryDto dto) => CustomCategory(
    name: dto.name,
    iconCodePoint: dto.iconCodePoint,
    colorValue: dto.colorValue,
  );

  static CustomCategoryDto toDto(CustomCategory entity) => CustomCategoryDto(
    name: entity.name,
    iconCodePoint: entity.iconCodePoint,
    colorValue: entity.colorValue,
  );
}
