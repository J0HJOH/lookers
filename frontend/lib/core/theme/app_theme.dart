import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Layout and sizing tokens.
class AppSizes {
  const AppSizes._();

  static const minTouchTarget = 48.0;
  static const maxContentWidth = 1280.0;
  static const mobileBreakpoint = 700.0;
  static const desktopBreakpoint = 1000.0;
  static const headerHeight = 76.0;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.background,
      secondary: AppColors.goldDeep,
      onSecondary: AppColors.paper,
      surface: AppColors.background,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.paper,
      outline: AppColors.line,
    );
    const square = RoundedRectangleBorder();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppText.bodyFamily,
      textTheme: TextTheme(
        bodyMedium: AppText.body(),
        bodyLarge: AppText.body(size: 16),
        bodySmall: AppText.body(size: 13, color: AppColors.inkMuted),
        titleLarge: AppText.display(28),
      ),
      dividerColor: AppColors.line,
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      splashFactory: NoSplash.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.background,
              disabledBackgroundColor: AppColors.line,
              shape: square,
              minimumSize: const Size(48, AppSizes.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              textStyle: AppText.button(),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                AppColors.goldDeep.withValues(alpha: 0.18),
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink),
          shape: square,
          minimumSize: const Size(48, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          textStyle: AppText.button(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: square,
          minimumSize: const Size(48, AppSizes.minTouchTarget),
          textStyle: AppText.button(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        labelStyle: AppText.body(color: AppColors.inkMuted, size: 14),
        floatingLabelStyle: AppText.body(color: AppColors.goldDeep, size: 14),
        errorStyle: AppText.body(color: AppColors.danger, size: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.goldDeep),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body(color: AppColors.background),
        behavior: SnackBarBehavior.floating,
        shape: square,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: square,
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.paper,
        ),
        side: const BorderSide(color: AppColors.ink),
      ),
    );
  }
}
