import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/prefs_storage.dart';

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  final controller = LocaleController();
  controller.loadLocale();
  return controller;
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en'));

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = PrefsStorage(prefs).locale;
    state = _resolveLocale(saved);
  }

  Future<void> updateLocale(Locale locale) async {
    if (state.languageCode == locale.languageCode) return;

    state = _resolveLocale(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await PrefsStorage(prefs).setLocale(state.languageCode);
  }

  Locale _resolveLocale(String? languageCode) {
    return switch (languageCode) {
      'ar' => const Locale('ar'),
      _ => const Locale('en'),
    };
  }
}
