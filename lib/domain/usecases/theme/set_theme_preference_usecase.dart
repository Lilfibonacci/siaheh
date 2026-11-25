import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/app_theme_preference.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';

class SetThemePreferenceUseCase
    implements PlainUseCase<void, AppThemePreference> {
  const SetThemePreferenceUseCase(this._repository);

  final ThemeRepository _repository;

  @override
  Future<void> call(AppThemePreference params) =>
      _repository.setThemePreference(params);
}
