/// Local persistence DTO for a user-created custom category stored in Hive.
class CustomCategoryDto {
  const CustomCategoryDto({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String name;
  final int iconCodePoint;
  final int colorValue;

  Map<String, dynamic> toMap() => {
    'name': name,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
  };

  factory CustomCategoryDto.fromMap(Map<dynamic, dynamic> m) =>
      CustomCategoryDto(
        name: m['name'] as String,
        iconCodePoint: m['iconCodePoint'] as int,
        colorValue: m['colorValue'] as int,
      );
}
