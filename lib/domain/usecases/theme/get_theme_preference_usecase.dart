import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/app_theme_preference.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';

class GetThemePreferenceUseCase
    implements SyncUseCase<AppThemePreference, NoParams> {
  const GetThemePreferenceUseCase(this._repository);

  final ThemeRepository _repository;

  @override
  AppThemePreference call(NoParams params) => _repository.getThemePreference();
}
