import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
