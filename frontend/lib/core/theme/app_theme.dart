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

  /// Material theme for [p]. Neumorphic surfaces and buttons are drawn by the widgets in
  /// `core/ui/neu.dart`; this sets the defaults for everything else (text, dialogs, menus, tiles).
  static ThemeData build(Palette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.accent,
      onSecondary: p.onPrimary,
      surface: p.background,
      onSurface: p.ink,
      error: p.danger,
      onError: p.onPrimary,
      outline: p.line,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      fontFamily: AppText.bodyFamily,
      textTheme: TextTheme(
        bodyMedium: AppText.body(),
        bodyLarge: AppText.body(size: 16),
        bodySmall: AppText.body(size: 13, color: p.inkMuted),
        titleLarge: AppText.display(28),
      ),
      dividerColor: p.line,
      dividerTheme: DividerThemeData(
        color: p.line.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),
      splashFactory: NoSplash.splashFactory,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          shape: rounded,
          minimumSize: const Size(48, AppSizes.minTouchTarget),
          textStyle: AppText.button(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        labelStyle: AppText.body(color: p.inkMuted, size: 14),
        floatingLabelStyle: AppText.body(color: p.accent, size: 14),
        errorStyle: AppText.body(color: p.danger, size: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: AppText.body(color: p.background),
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.surfaceAlt,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.inkMuted),
      ),
      popupMenuTheme: PopupMenuThemeData(color: p.background, shape: rounded),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: p.ink,
        collapsedIconColor: p.ink,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    );
  }
}
