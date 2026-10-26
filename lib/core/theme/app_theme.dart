import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // (Light Mode)
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.goldLightTheme,
      fontFamily: AppFonts.family,

      colorScheme: const ColorScheme.light(
        primary: AppColors.goldLightTheme,
        secondary: AppColors.emeraldLight,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        error: AppColors.crimsonLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: AppFonts.family,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // (Dark Mode)
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.goldDarkTheme,
      fontFamily: AppFonts.family,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldDarkTheme,
        secondary: AppColors.emeraldDark,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceLight,
        error: AppColors.crimsonDark,
        onPrimary: AppColors.darkBackground,
        onSecondary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: AppFonts.family,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
    );
  }
}
