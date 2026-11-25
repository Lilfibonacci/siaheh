import 'package:siaheh/data/datasources/theme_local_data_source.dart';
import 'package:siaheh/data/mappers/theme_preference_mapper.dart';
import 'package:siaheh/domain/entities/app_theme_preference.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';

/// Single source of truth for reading and persisting the user's theme mode.
class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(this._localDataSource);

  final ThemeLocalDataSource _localDataSource;

  @override
  AppThemePreference getThemePreference() =>
      ThemePreferenceMapper.fromStorageName(_localDataSource.themeModeName);

  @override
  Future<void> setThemePreference(AppThemePreference preference) =>
      _localDataSource.setThemeModeName(
        ThemePreferenceMapper.toStorageName(preference),
      );
}
