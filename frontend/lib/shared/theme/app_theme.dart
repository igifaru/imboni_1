import 'package:flutter/material.dart';
import 'colors.dart';

/// Imboni App Theme Configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ImboniColors.primary,
      onPrimary: Colors.white,
      secondary: ImboniColors.secondary,
      onSecondary: Colors.white,
      tertiary: ImboniColors.accent,
      error: ImboniColors.error,
      surface: ImboniColors.surface,
      onSurface: ImboniColors.textPrimary,
      outline: ImboniColors.outline,
    ),
    scaffoldBackgroundColor: ImboniColors.background,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: ImboniColors.surface,
      foregroundColor: ImboniColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ImboniColors.outline),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ImboniColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ImboniColors.primary,
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: ImboniColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ImboniColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ImboniColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ImboniColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ImboniColors.surface,
      selectedItemColor: ImboniColors.primary,
      unselectedItemColor: ImboniColors.textSecondary,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: ImboniColors.primary,
      onPrimary: Colors.white,
      secondary: ImboniColors.secondaryLight,
      onSecondary: Colors.white,
      tertiary: ImboniColors.accent,
      error: ImboniColors.error,
      surface: ImboniColors.surfaceDark,
      onSurface: ImboniColors.textPrimaryDark,
      outline: ImboniColors.outlineDark,
    ),
    scaffoldBackgroundColor: ImboniColors.backgroundDark,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: ImboniColors.surfaceDark,
      foregroundColor: ImboniColors.textPrimaryDark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: ImboniColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ImboniColors.outlineDark),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ImboniColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ImboniColors.primary,
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: ImboniColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ImboniColors.surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ImboniColors.outlineDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ImboniColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ImboniColors.surfaceDark,
      selectedItemColor: ImboniColors.primary,
      unselectedItemColor: ImboniColors.textSecondaryDark,
    ),
  );
}
