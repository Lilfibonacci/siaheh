import 'package:equatable/equatable.dart';

/// A learned user categorization rule mapping a normalized merchant name or
/// keyword to a category (and optional preferred display title).
class CategoryRule extends Equatable {
  const CategoryRule({
    required this.pattern,
    required this.categoryId,
    this.preferredTitle,
  });

  /// Normalized merchant or keyword (e.g. `ایرانسل`, `اسنپ`, `کافه لمیز`).
  final String pattern;

  /// Target category name (built-in or custom).
  final String categoryId;

  /// Optional preferred title to assign to matching future transactions.
  final String? preferredTitle;

  @override
  List<Object?> get props => [pattern, categoryId, preferredTitle];
}
