import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/prefs_storage.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
      final controller = ThemeModeController();
      controller.loadThemeMode();
      return controller;
    });

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system);

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = PrefsStorage(prefs).themeMode;
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (state == mode) return;

    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await PrefsStorage(prefs).setThemeMode(mode);
  }
}
