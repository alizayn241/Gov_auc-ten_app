import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/admin/presentation/view/admin_dashboard_screen.dart';

const supabaseUrl = 'https://ejdvmtotabwxnamzvdbe.supabase.co';
const supabaseAnonKey = 'sb_publishable_m-nK4L8VJLQENZJHU-_3YQ_EkHHod0p';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: GovAuctionApp()));
}

class GovAuctionApp extends ConsumerWidget {
  const GovAuctionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Admin Feature',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AdminDashboardScreen(),
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}



