import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// Standard [Bloc] managing light/dark [ThemeMode] with optional persistence.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({
    ThemeMode initialMode = ThemeMode.system,
    this.onModeChanged,
  }) : super(ThemeState(initialMode)) {
    on<ThemeToggled>(_onToggled);
  }

  final Future<void> Function(ThemeMode mode)? onModeChanged;

  static ThemeMode parseModeName(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> _onToggled(ThemeToggled event, Emitter<ThemeState> emit) async {
    final ThemeMode next = event.currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    emit(ThemeState(next));
    await onModeChanged?.call(next);
  }
}
