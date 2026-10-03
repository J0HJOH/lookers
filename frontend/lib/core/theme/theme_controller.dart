import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

enum AppThemeMode { system, light, dark }

/// Owns light / dark mode. The choice is remembered on the device; "system" follows the OS.
///
/// Widgets read colours from `AppColors` (the active palette), so after a switch every widget must
/// rebuild. [rebuildAll] does that while keeping state (typed text, scroll, selections).
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController(this._prefs) {
    final stored = _prefs?.getString(_key);
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => AppThemeMode.system,
    );
    AppColors.use(_resolve());
    WidgetsBinding.instance.addObserver(this);
  }

  final SharedPreferences? _prefs;
  static const _key = 'lookers.themeMode';
  late AppThemeMode _mode;

  AppThemeMode get mode => _mode;
  Palette get palette => AppColors.palette;
  bool get isDark => AppColors.palette.isDark;

  Palette _resolve() {
    switch (_mode) {
      case AppThemeMode.light:
        return Palette.light;
      case AppThemeMode.dark:
        return Palette.dark;
      case AppThemeMode.system:
        return ui.PlatformDispatcher.instance.platformBrightness ==
                Brightness.dark
            ? Palette.dark
            : Palette.light;
    }
  }

  void setMode(AppThemeMode mode) {
    _mode = mode;
    _prefs?.setString(_key, mode.name);
    _apply();
  }

  /// Header button: flips between light and dark.
  void toggle() => setMode(isDark ? AppThemeMode.light : AppThemeMode.dark);

  @override
  void didChangePlatformBrightness() {
    if (_mode == AppThemeMode.system) _apply();
  }

  void _apply() {
    AppColors.use(_resolve());
    notifyListeners();
    rebuildAll();
  }

  /// Marks every mounted element dirty so widgets that read `AppColors` pick up the new palette.
  /// State objects are kept, so nothing the user typed or selected is lost.
  static void rebuildAll() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
