import 'package:flutter/material.dart';
import 'color_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColorConstants.primary,
          surface: ColorConstants.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ColorConstants.primary,
          foregroundColor: ColorConstants.onPrimary,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primary,
            foregroundColor: ColorConstants.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: ColorConstants.primary,
          foregroundColor: ColorConstants.onPrimary,
        ),
      );
}
