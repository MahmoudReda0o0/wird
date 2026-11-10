import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_colors.dart';

/// Holds the current theme mode. Defaults to following the device setting.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.system,
  );

  /// Switches between light and dark, based on what is shown right now.
  static void toggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.appWhite,
    surface: AppColors.appWhite,
    onSurface: AppColors.appBlack,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.appGreen,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.appGreen,
      secondary: AppColors.appBlue,
      tertiary: AppColors.appGold,
      surface: surface,
      onSurface: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: onSurface),
    );
  }
}
