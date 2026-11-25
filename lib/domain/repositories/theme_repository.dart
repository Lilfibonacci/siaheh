import 'package:siaheh/domain/entities/app_theme_preference.dart';

/// Contract for persisting and reading the user's theme preference.
abstract interface class ThemeRepository {
  AppThemePreference getThemePreference();

  Future<void> setThemePreference(AppThemePreference preference);
}
