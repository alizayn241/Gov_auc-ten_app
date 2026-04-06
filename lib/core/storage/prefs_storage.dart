import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsStorage {
  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';
  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  final SharedPreferences prefs;

  PrefsStorage(this.prefs);

  String? get locale => prefs.getString(_localeKey);
  Future<void> setLocale(String value) => prefs.setString(_localeKey, value);

  ThemeMode get themeMode {
    final savedValue = prefs.getString(_themeModeKey);
    return switch (savedValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode value) {
    final serialized = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    return prefs.setString(_themeModeKey, serialized);
  }

  bool get hasSeenOnboarding => prefs.getBool(_hasSeenOnboardingKey) ?? false;

  Future<void> setHasSeenOnboarding(bool value) {
    return prefs.setBool(_hasSeenOnboardingKey, value);
  }
}
