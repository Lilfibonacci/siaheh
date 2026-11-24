/// Pure domain representation of the user's persisted theme preference.
enum AppThemePreference { system, light, dark }

/// Contract for persisting and reading the user's theme preference.
abstract interface class ThemeRepository {
  AppThemePreference getThemePreference();

  Future<void> setThemePreference(AppThemePreference preference);
}
