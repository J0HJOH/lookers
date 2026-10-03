import 'package:flutter/material.dart';

/// One complete colour set. Raw colour values may ONLY be written in this folder
/// (test/design_system_test.dart). All text colours are >= 4.5:1 on [background].
///
/// The look is neumorphic ("soft UI"): surfaces share the page colour and are lifted or pressed
/// with a light and a dark shadow, so [shadowLight] / [shadowDark] matter as much as the fills.
class Palette {
  const Palette({
    required this.brightness,
    required this.background,
    required this.surfaceAlt,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.accent,
    required this.accentSoft,
    required this.primary,
    required this.primaryDeep,
    required this.onPrimary,
    required this.danger,
    required this.success,
    required this.shadowLight,
    required this.shadowDark,
  });

  final Brightness brightness;
  final Color background;
  final Color surfaceAlt;
  final Color line;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color accent;
  final Color accentSoft;
  final Color primary;
  final Color primaryDeep;
  final Color onPrimary;
  final Color danger;
  final Color success;
  final Color shadowLight;
  final Color shadowDark;

  bool get isDark => brightness == Brightness.dark;

  /// Soft lavender: mid-tone base so the white highlight and violet shadow both read.
  static const light = Palette(
    brightness: Brightness.light,
    background: Color(0xFFE6E1F3),
    surfaceAlt: Color(0xFFDDD6EE),
    line: Color(0xFFCFC7E4),
    ink: Color(0xFF241C3D),
    inkSoft: Color(0xFF40375F),
    inkMuted: Color(0xFF5F5681),
    accent: Color(0xFF5B3FC4),
    accentSoft: Color(0xFF9B84E8),
    primary: Color(0xFF6342D6),
    primaryDeep: Color(0xFF4A2FB0),
    onPrimary: Color(0xFFFFFFFF),
    danger: Color(0xFFA32244),
    success: Color(0xFF2F6B4F),
    shadowLight: Color(0xFFFBF9FF),
    shadowDark: Color(0xFFB9AFD8),
  );

  /// Deep violet night: lifted light shadow, near-black violet dark shadow.
  static const dark = Palette(
    brightness: Brightness.dark,
    background: Color(0xFF221C37),
    surfaceAlt: Color(0xFF1C1730),
    line: Color(0xFF342C50),
    ink: Color(0xFFF0ECFD),
    inkSoft: Color(0xFFD3CCEB),
    inkMuted: Color(0xFFA89FC8),
    accent: Color(0xFFB9A5FF),
    accentSoft: Color(0xFF7E64D8),
    primary: Color(0xFFB7A2FF),
    primaryDeep: Color(0xFF9B83F0),
    onPrimary: Color(0xFF1B1433),
    danger: Color(0xFFFF8FA8),
    success: Color(0xFF7DD4A8),
    shadowLight: Color(0xFF30284F),
    shadowDark: Color(0xFF130F23),
  );
}

/// Semantic tokens used by widgets. They read the ACTIVE palette, which `ThemeController` switches
/// (and then rebuilds the app), so widgets don't need to know whether dark mode is on.
class AppColors {
  const AppColors._();

  static Palette _p = Palette.light;
  static Palette get palette => _p;
  static void use(Palette palette) => _p = palette;

  static Color get background => _p.background;

  /// A slightly recessed tone: input fill, image placeholders, panels.
  static Color get surface => _p.surfaceAlt;
  static Color get line => _p.line;
  static Color get ink => _p.ink;
  static Color get inkSoft => _p.inkSoft;
  static Color get inkMuted => _p.inkMuted;

  /// Purple for links, focus, ratings and emphasis text.
  static Color get accent => _p.accent;

  /// Decoration only (never text): swatch rings, soft highlights.
  static Color get accentSoft => _p.accentSoft;

  /// Fill of primary buttons; [onPrimary] is the text/icon colour on it.
  static Color get primary => _p.primary;
  static Color get primaryDeep => _p.primaryDeep;
  static Color get onPrimary => _p.onPrimary;
  static Color get danger => _p.danger;
  static Color get success => _p.success;
  static Color get shadowLight => _p.shadowLight;
  static Color get shadowDark => _p.shadowDark;

  /// Text drawn over photos always sits on a dark scrim, so it is white in both modes.
  /// Fully transparent (ink splash/highlight off, invisible borders).
  static const clear = Color(0x00000000);

  static const onPhoto = Color(0xFFFFFFFF);
  static const photoScrim = Color(0xB31B1433);
  static const photoScrimClear = Color(0x001B1433);

  /// A product's own colour variant (e.g. `#14110F` from the database), for swatches.
  /// This is product data, not a theme colour.
  static Color fromHex(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | (value ?? 0xBDB7AB));
  }
}
