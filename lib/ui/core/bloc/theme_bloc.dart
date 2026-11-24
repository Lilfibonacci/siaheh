import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';

sealed class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Switches between light and dark theme based on the currently rendered
/// [currentBrightness], so tapping from [ThemeMode.system] always flips cleanly.
final class ThemeToggled extends ThemeEvent {
  const ThemeToggled({required this.currentBrightness});

  final Brightness currentBrightness;

  @override
  List<Object?> get props => [currentBrightness];
}

final class ThemeState extends Equatable {
  const ThemeState(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

/// Standard [Bloc] managing light/dark [ThemeMode] backed by [ThemeRepository].
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({
    ThemeRepository? repository,
    ThemeMode? initialMode,
  }) : _repository = repository,
       super(
         ThemeState(
           initialMode ??
               (repository != null
                   ? _toThemeMode(repository.getThemePreference())
                   : ThemeMode.system),
         ),
       ) {
    on<ThemeToggled>(_onToggled);
  }

  final ThemeRepository? _repository;

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
    await _repository?.setThemePreference(_toPreference(next));
  }
}
