import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.light(
      primary:AppLightColors.primary,
      surface: AppLightColors.surface,
      onSurface: AppLightColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppLightColors.background,

  );
  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: AppDarkColors.primary,
      surface: AppDarkColors.surface,
      onSurface: AppDarkColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppDarkColors.background,
  );
}