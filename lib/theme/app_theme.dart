import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  // Recreate themes on rebuild so hot reload cannot retain the previous palette.
  static ThemeData get lightTheme => _create(Brightness.light);
  static ThemeData get darkTheme => _create(Brightness.dark);

  static ThemeData _create(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppLightColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: dark ? AppDarkColors.primary : AppLightColors.primary,
          onPrimary: dark ? const Color(0xFF352F26) : AppLightColors.surface,
          primaryContainer: dark
              ? const Color(0xFF4B4236)
              : const Color(0xFFEAE1D0),
          onPrimaryContainer: dark
              ? const Color(0xFFF5EAD9)
              : const Color(0xFF3F382D),
          secondary: dark ? const Color(0xFFC5B69F) : const Color(0xFF826E58),
          onSecondary: dark ? const Color(0xFF352F26) : AppLightColors.surface,
          secondaryContainer: dark
              ? const Color(0xFF453D32)
              : const Color(0xFFEEE5D6),
          onSecondaryContainer: dark
              ? const Color(0xFFF3E8D7)
              : const Color(0xFF443A2D),
          tertiary: dark ? const Color(0xFFC9BEB0) : const Color(0xFF786F62),
          onTertiary: dark ? const Color(0xFF352F26) : AppLightColors.surface,
          tertiaryContainer: dark
              ? const Color(0xFF433D34)
              : const Color(0xFFE9E1D6),
          onTertiaryContainer: dark
              ? const Color(0xFFF3EEE4)
              : const Color(0xFF40392F),
          surface: dark ? AppDarkColors.surface : AppLightColors.surface,
          onSurface: dark
              ? AppDarkColors.textPrimary
              : AppLightColors.textPrimary,
          onSurfaceVariant: dark
              ? const Color(0xFFBDB3A5)
              : const Color(0xFF71685D),
          surfaceContainerLowest: dark
              ? const Color(0xFF191714)
              : const Color(0xFFFFFDF8),
          surfaceContainerLow: dark
              ? const Color(0xFF35312B)
              : const Color(0xFFF2EDE2),
          surfaceContainer: dark
              ? const Color(0xFF3A352E)
              : const Color(0xFFEFE8DC),
          surfaceContainerHigh: dark
              ? const Color(0xFF423B32)
              : const Color(0xFFE7DECD),
          surfaceContainerHighest: dark
              ? const Color(0xFF4B4338)
              : const Color(0xFFE1D6C4),
          outline: dark ? const Color(0xFF8B8172) : const Color(0xFF9D9281),
          outlineVariant: dark
              ? const Color(0xFF51493D)
              : const Color(0xFFE0D7C7),
          surfaceTint: dark ? AppDarkColors.primary : AppLightColors.primary,
        );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? AppDarkColors.background
          : AppLightColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: scheme.outlineVariant,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .2),
        selectionHandleColor: scheme.primary,
      ),
    );
  }
}
