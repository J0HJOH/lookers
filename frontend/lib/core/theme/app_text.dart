import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography. Cormorant Garamond for display, Jost for body, Pinyon Script for the logo.
/// Fonts are bundled (assets/fonts), so nothing is fetched from Google at runtime.
class AppText {
  const AppText._();

  static const displayFamily = 'Cormorant';
  static const bodyFamily = 'Jost';
  static const scriptFamily = 'Pinyon';

  static TextStyle display(
    double size, {
    Color color = AppColors.ink,
    bool italic = false,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontSize: size,
    height: 1.05,
    letterSpacing: -0.5,
    color: color,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontVariations: const [FontVariation.weight(500)],
  );

  static TextStyle body({
    double size = 15,
    Color color = AppColors.inkSoft,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: size,
    height: 1.55,
    color: color,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );

  /// Small, wide-tracked uppercase label.
  static TextStyle eyebrow({Color color = AppColors.inkMuted}) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 11,
    letterSpacing: 3,
    height: 1.4,
    color: color,
    fontVariations: const [FontVariation.weight(400)],
  );

  static TextStyle button() => const TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    letterSpacing: 2.6,
    fontVariations: [FontVariation.weight(500)],
  );
}
