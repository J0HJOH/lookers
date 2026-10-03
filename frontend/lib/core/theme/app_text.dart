import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography. Jost (geometric, soft) for everything; Pinyon Script is for the logo only.
/// Fonts are bundled (assets/fonts), so nothing is fetched from Google at runtime.
/// Colours default to the active palette at call time, so they follow dark mode.
class AppText {
  const AppText._();

  static const bodyFamily = 'Jost';
  static const scriptFamily = 'Pinyon';

  static TextStyle display(double size, {Color? color}) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: size,
    height: 1.1,
    letterSpacing: -0.6,
    color: color ?? AppColors.ink,
    fontVariations: const [FontVariation.weight(500)],
  );

  static TextStyle body({
    double size = 15,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: size,
    height: 1.55,
    color: color ?? AppColors.inkSoft,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );

  /// Small, wide-tracked uppercase label.
  static TextStyle eyebrow({Color? color}) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 11,
    letterSpacing: 2.6,
    height: 1.4,
    color: color ?? AppColors.inkMuted,
    fontVariations: const [FontVariation.weight(500)],
  );

  static TextStyle button({Color? color}) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    letterSpacing: 2.4,
    color: color,
    fontVariations: const [FontVariation.weight(600)],
  );
}
