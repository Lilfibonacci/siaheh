import 'package:siaheh/data/services/local/theme_storage_service.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';

/// Single source of truth for reading and persisting the user's theme mode.
class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(this._storage);

  final ThemeStorageService _storage;

  @override
  AppThemePreference getThemePreference() => switch (_storage.themeModeName) {
    'light' => AppThemePreference.light,
    'dark' => AppThemePreference.dark,
    _ => AppThemePreference.system,
  };

  @override
  Future<void> setThemePreference(AppThemePreference preference) =>
      _storage.setThemeModeName(preference.name);
}
