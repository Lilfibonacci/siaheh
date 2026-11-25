/// Local persistence DTO for a learned merchant-to-category rule in Hive.
class CategoryRuleDto {
  const CategoryRuleDto({
    required this.pattern,
    required this.categoryId,
    this.preferredTitle,
  });

  final String pattern;
  final String categoryId;
  final String? preferredTitle;

  Map<String, dynamic> toMap() => {
    'pattern': pattern,
    'categoryId': categoryId,
    'preferredTitle': preferredTitle,
  };

  factory CategoryRuleDto.fromMap(Map<dynamic, dynamic> m) => CategoryRuleDto(
    pattern: m['pattern'] as String,
    categoryId: m['categoryId'] as String,
    preferredTitle: m['preferredTitle'] as String?,
  );
}
