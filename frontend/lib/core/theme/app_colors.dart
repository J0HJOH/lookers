import 'package:flutter/painting.dart';

/// Raw brand values. Raw colours may ONLY be written in this folder (test/design_system_test.dart).
class AppPalette {
  const AppPalette._();

  static const ivory50 = Color(0xFFFAF7F1);
  static const ivory100 = Color(0xFFF3EEE4);
  static const ivory200 = Color(0xFFE8E0D0);
  static const ink900 = Color(0xFF14110F);
  static const ink700 = Color(0xFF3A342F);
  static const ink500 = Color(0xFF6B635B);
  static const gold500 = Color(0xFFB08D57);
  static const gold600 = Color(0xFF8F6F3F);
  static const burgundy700 = Color(0xFF6E1F2B);
  static const sage700 = Color(0xFF3F5A45);
  static const white = Color(0xFFFFFFFF);
}

/// Semantic tokens used by widgets. Text tokens are all >= 4.5:1 on [background].
class AppColors {
  const AppColors._();

  static const background = AppPalette.ivory50;
  static const surface = AppPalette.ivory100;
  static const line = AppPalette.ivory200;
  static const ink = AppPalette.ink900;
  static const inkSoft = AppPalette.ink700;
  static const inkMuted = AppPalette.ink500;

  /// Decoration and selection only. Never for text (low contrast).
  static const gold = AppPalette.gold500;
  static const goldDeep = AppPalette.gold600;
  static const danger = AppPalette.burgundy700;
  static const success = AppPalette.sage700;
  static const paper = AppPalette.white;

  /// A product's own colour variant (e.g. `#14110F` from the database), for swatches.
  /// This is product data, not a theme colour.
  static Color fromHex(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | (value ?? 0xBDB7AB));
  }

  /// Scrim over photos so white text stays readable.
  static const photoScrim = Color(0xB314110F);
  static const photoScrimClear = Color(0x0014110F);
}
