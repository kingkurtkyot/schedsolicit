import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/color_schemes.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeState>((ref) {
  return ThemeNotifier();
});

class AppThemeState {
  final ThemeMode themeMode;
  final GreenShade greenShade;

  const AppThemeState({
    this.themeMode = ThemeMode.system,
    this.greenShade = GreenShade.emerald,
  });

  ThemeData get lightTheme => AppTheme.light(greenShade);
  ThemeData get darkTheme => AppTheme.dark(greenShade);

  AppThemeState copyWith({
    ThemeMode? themeMode,
    GreenShade? greenShade,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      greenShade: greenShade ?? this.greenShade,
    );
  }
}

class ThemeNotifier extends StateNotifier<AppThemeState> {
  static const String _modeKey = 'app_theme_mode';
  static const String _shadeKey = 'app_green_shade';

  ThemeNotifier() : super(const AppThemeState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_modeKey);
    final shadeIndex = prefs.getInt(_shadeKey);

    ThemeMode mode = ThemeMode.system;
    if (modeIndex != null && modeIndex < ThemeMode.values.length) {
      mode = ThemeMode.values[modeIndex];
    }

    GreenShade shade = GreenShade.emerald;
    if (shadeIndex != null && shadeIndex < GreenShade.values.length) {
      shade = GreenShade.values[shadeIndex];
    }

    state = AppThemeState(themeMode: mode, greenShade: shade);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
  }

  Future<void> setGreenShade(GreenShade shade) async {
    state = state.copyWith(greenShade: shade);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shadeKey, shade.index);
  }
}
