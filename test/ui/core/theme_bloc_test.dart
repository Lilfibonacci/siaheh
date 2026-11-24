import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';
import 'package:siaheh/ui/core/bloc/theme_bloc.dart';

class _InMemoryThemeRepository implements ThemeRepository {
  _InMemoryThemeRepository([this._preference = AppThemePreference.system]);

  AppThemePreference _preference;

  @override
  AppThemePreference getThemePreference() => _preference;

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    _preference = preference;
  }
}

void main() {
  test('ThemeBloc loads initial preference and persists toggled mode', () async {
    final repo = _InMemoryThemeRepository(AppThemePreference.dark);
    final bloc = ThemeBloc(repository: repo);

    expect(bloc.state.mode, ThemeMode.dark);

    bloc.add(const ThemeToggled(currentBrightness: Brightness.dark));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.mode, ThemeMode.light);
    expect(repo.getThemePreference(), AppThemePreference.light);

    bloc.add(const ThemeToggled(currentBrightness: Brightness.light));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.mode, ThemeMode.dark);
    expect(repo.getThemePreference(), AppThemePreference.dark);

    await bloc.close();
  });
}
