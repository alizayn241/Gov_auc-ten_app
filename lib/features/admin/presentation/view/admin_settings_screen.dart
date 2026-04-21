import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/app_page_back_button.dart';
import 'settings/settings_widgets.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _maintenance = false;
  bool _require2fa = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.systemSettings),
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsHint(
            title: l10n.platformConfiguration,
            subtitle: l10n.platformConfigurationSubtitle,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                RadioListTile<Locale>(
                  value: const Locale('en'),
                  groupValue: Locale(locale.languageCode),
                  onChanged: _onLocaleChanged,
                  title: Text(l10n.english),
                  subtitle: Text(l10n.languageSubtitle),
                ),
                const Divider(height: 0),
                RadioListTile<Locale>(
                  value: const Locale('ar'),
                  groupValue: Locale(locale.languageCode),
                  onChanged: _onLocaleChanged,
                  title: Text(l10n.arabic),
                  subtitle: Text(l10n.languageSubtitle),
                ),
                const Divider(height: 0),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: _onThemeModeChanged,
                  title: Text(l10n.useSystemTheme),
                  subtitle: Text(l10n.useSystemThemeSubtitle),
                ),
                const Divider(height: 0),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: _onThemeModeChanged,
                  title: Text(l10n.lightMode),
                  subtitle: Text(l10n.lightModeSubtitle),
                ),
                const Divider(height: 0),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: _onThemeModeChanged,
                  title: Text(l10n.darkMode),
                  subtitle: Text(l10n.darkModeSubtitle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _maintenance,
                  onChanged: (value) => setState(() => _maintenance = value),
                  title: Text(l10n.maintenanceMode),
                  subtitle: Text(l10n.maintenanceModeSubtitle),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _require2fa,
                  onChanged: (value) => setState(() => _require2fa = value),
                  title: Text(l10n.require2fa),
                  subtitle: Text(l10n.require2faSubtitle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.savedDemo)),
            ),
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _onThemeModeChanged(ThemeMode? mode) {
    if (mode == null) return;
    ref.read(themeModeProvider.notifier).updateThemeMode(mode);
  }

  void _onLocaleChanged(Locale? locale) {
    if (locale == null) return;
    ref.read(localeProvider.notifier).updateLocale(locale);
  }
}
