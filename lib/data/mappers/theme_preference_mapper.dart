import 'package:siaheh/domain/entities/app_theme_preference.dart';

class ThemePreferenceMapper {
  const ThemePreferenceMapper._();

  static AppThemePreference fromStorageName(String? raw) => switch (raw) {
    'light' => AppThemePreference.light,
    'dark' => AppThemePreference.dark,
    _ => AppThemePreference.system,
  };

  static String toStorageName(AppThemePreference preference) => preference.name;
}
