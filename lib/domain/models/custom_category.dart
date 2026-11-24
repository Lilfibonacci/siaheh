import 'package:equatable/equatable.dart';

/// A user-created expense/income category stored locally in Hive.
class CustomCategory extends Equatable {
  const CustomCategory({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String name;

  /// Material Icons code point (e.g. `Icons.coffee_rounded.codePoint`).
  final int iconCodePoint;

  /// ARGB32 color value (e.g. `0xFF14B8A6`).
  final int colorValue;

  Map<String, dynamic> toMap() => {
    'name': name,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
  };

  factory CustomCategory.fromMap(Map<dynamic, dynamic> m) => CustomCategory(
    name: m['name'] as String,
    iconCodePoint: m['iconCodePoint'] as int,
    colorValue: m['colorValue'] as int,
  );

  @override
  List<Object?> get props => [name, iconCodePoint, colorValue];
}
