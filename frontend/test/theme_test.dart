import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lookers/core/theme/app_colors.dart';
import 'package:lookers/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

double _luminance(Color c) {
  double f(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  setUp(() => AppColors.use(Palette.light));

  group('palettes', () {
    for (final entry in {
      'light': Palette.light,
      'dark': Palette.dark,
    }.entries) {
      final p = entry.value;
      test('${entry.key}: text and accent colours are readable (>= 4.5:1)', () {
        for (final text in {
          'ink': p.ink,
          'inkSoft': p.inkSoft,
          'inkMuted': p.inkMuted,
          'accent': p.accent,
          'danger': p.danger,
          'success': p.success,
        }.entries) {
          expect(
            contrast(text.value, p.background),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} ${text.key} on background',
          );
          expect(
            contrast(text.value, p.surfaceAlt),
            greaterThanOrEqualTo(4.0),
            reason: '${entry.key} ${text.key} on recessed surface',
          );
        }
        expect(
          contrast(p.onPrimary, p.primary),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} button text',
        );
        expect(
          contrast(p.onPrimary, p.primaryDeep),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} pressed button text',
        );
      });
    }
    test(
      'the light shadow is lighter and the dark shadow darker than the surface (needed for the soft look)',
      () {
        for (final p in [Palette.light, Palette.dark]) {
          expect(
            _luminance(p.shadowLight),
            greaterThan(_luminance(p.background)),
          );
          expect(_luminance(p.shadowDark), lessThan(_luminance(p.background)));
        }
      },
    );
  });

  group('ThemeController', () {
    test('remembers the chosen mode on the device', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(prefs);
      addTearDown(controller.dispose);
      controller.setMode(AppThemeMode.dark);
      expect(AppColors.palette.isDark, isTrue);
      final restored = ThemeController(prefs);
      addTearDown(restored.dispose);
      expect(restored.mode, AppThemeMode.dark);
      expect(restored.isDark, isTrue);
    });

    test('toggle flips between light and dark', () {
      final controller = ThemeController(null)..setMode(AppThemeMode.light);
      addTearDown(controller.dispose);
      controller.toggle();
      expect(controller.isDark, isTrue);
      controller.toggle();
      expect(controller.isDark, isFalse);
    });
  });

  testWidgets(
    'the header button switches the whole app to dark mode and keeps typed text',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = previewApp();
      app.theme.setMode(AppThemeMode.light);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'jacket');
      expect(AppColors.palette.isDark, isFalse);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor ??
            Theme.of(
              tester.element(find.byType(Scaffold).first),
            ).scaffoldBackgroundColor,
        Palette.light.background,
      );

      await tester.tap(find.byTooltip('Switch to dark mode'));
      await tester.pumpAndSettle();

      expect(AppColors.palette.isDark, isTrue);
      expect(
        Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).scaffoldBackgroundColor,
        Palette.dark.background,
      );
      expect(find.byTooltip('Switch to light mode'), findsOneWidget);
      // State is preserved across the switch: the search box still holds what was typed.
      expect(find.text('jacket'), findsOneWidget);
    },
  );
}
