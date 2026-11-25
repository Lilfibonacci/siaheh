import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/app_theme_preference.dart';
import 'package:siaheh/domain/usecases/theme/get_theme_preference_usecase.dart';
import 'package:siaheh/domain/usecases/theme/set_theme_preference_usecase.dart';
import 'package:siaheh/presentation/bloc/theme/theme_event.dart';
import 'package:siaheh/presentation/bloc/theme/theme_state.dart';

export 'theme_event.dart';
export 'theme_state.dart';

/// Standard [Bloc] managing light/dark [ThemeMode] backed by theme UseCases.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({
    GetThemePreferenceUseCase? getThemePreference,
    this._setThemePreference,
    ThemeMode? initialMode,
  }) : super(
         ThemeState(
           initialMode ??
               (getThemePreference != null
                   ? _toThemeMode(getThemePreference(const NoParams()))
                   : ThemeMode.system),
         ),
       ) {
    on<ThemeToggled>(_onToggled);
  }

  final SetThemePreferenceUseCase? _setThemePreference;

  static ThemeMode _toThemeMode(AppThemePreference preference) =>
      switch (preference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      };

  static AppThemePreference _toPreference(ThemeMode mode) => switch (mode) {
    ThemeMode.light => AppThemePreference.light,
    ThemeMode.dark => AppThemePreference.dark,
    ThemeMode.system => AppThemePreference.system,
  };

  Future<void> _onToggled(ThemeToggled event, Emitter<ThemeState> emit) async {
    final ThemeMode next = event.currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    emit(ThemeState(next));
    await _setThemePreference?.call(_toPreference(next));
  }
}
