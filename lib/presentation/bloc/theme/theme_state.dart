import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

final class ThemeState extends Equatable {
  const ThemeState(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => [mode];
}
