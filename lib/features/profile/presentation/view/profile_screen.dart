import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/features/auth/presentation/viewmodel/auth_view_model.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import 'profile/profile_hero.dart';
import 'profile/profile_stats.dart';
import 'profile/profile_tiles.dart';
import 'shared/profile_shared.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _heroAnim;
  late final Animation<double> _statsAnim;
  late final Animation<double> _bodyAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _heroAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _statsAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
    );
    _bodyAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authViewModelProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final role = (auth.role ?? 'user').toLowerCase();
    final isAdmin = role == 'admin';
    final isStaff = role == 'staff';
    final isCitizen = !isAdmin && !isStaff;
    final isPhone = MediaQuery.sizeOf(context).width < 700;

    final roleLabel = isAdmin
        ? l10n.roleAdmin
        : isStaff
            ? l10n.roleStaff
            : l10n.roleCitizen;

    final roleIcon = isAdmin
        ? Icons.admin_panel_settings_rounded
        : isStaff
            ? Icons.verified_user_rounded
            : Icons.shield_rounded;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ProfileTopBarDelegate(
              title: l10n.profileTitle,
              onBack: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _heroAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(_heroAnim),
                child: ProfileHero(
                  isAuthenticated: auth.isAuthenticated,
                  roleLabel: roleLabel,
                  roleIcon: roleIcon,
                  isPhone: isPhone,
                  subtitle: auth.isAuthenticated
                      ? l10n.profileHeroReadySubtitle
                      : l10n.profileHeroGuestSubtitle,
                ),
              ),
            ),
          ),
          if (auth.isAuthenticated)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _statsAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(_statsAnim),
                  child: const ProfileStatStrip(),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _bodyAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    if (auth.isAuthenticated && (isAdmin || isStaff)) ...[
                      ProfileSectionLabel(label: l10n.administration),
                      const SizedBox(height: 8),
                      if (isAdmin)
                        ProfileNavTile(
                          icon: Icons.dashboard_customize_rounded,
                          iconColor: ProfileTheme.blue,
                          iconBg: const Color(0xFFE3F0FC),
                          title: l10n.adminDashboard,
                          subtitle: l10n.adminDashboardSubtitle,
                          onTap: () => context.push('/admin'),
                        ),
                      if (isStaff) ...[
                        ProfileNavTile(
                          icon: Icons.verified_rounded,
                          iconColor: ProfileTheme.liveGreen,
                          iconBg: const Color(0xFFE8F5E9),
                          title: l10n.approvals,
                          subtitle: l10n.approvalsSubtitle,
                          onTap: () => context.push('/staff/approvals'),
                        ),
                        ProfileNavTile(
                          icon: Icons.rule_folder_rounded,
                          iconColor: const Color(0xFF7B1FA2),
                          iconBg: const Color(0xFFF3E5F5),
                          title: l10n.processes,
                          subtitle: l10n.processesSubtitle,
                          onTap: () => context.push('/staff/processes'),
                        ),
                      ],
                      const SizedBox(height: 18),
                    ],
                    if (auth.isAuthenticated && isCitizen) ...[
                      ProfileSectionLabel(label: l10n.updates),
                      const SizedBox(height: 8),
                      ProfileNavTile(
                        icon: Icons.receipt_long_rounded,
                        iconColor: ProfileTheme.blue,
                        iconBg: const Color(0xFFE3F0FC),
                        title: l10n.myPayments,
                        subtitle: l10n.myPaymentsSubtitle,
                        onTap: () => context.push('/my-payments'),
                      ),
                      ProfileNavTile(
                        icon: Icons.notifications_rounded,
                        iconColor: ProfileTheme.liveGreen,
                        iconBg: const Color(0xFFE8F5E9),
                        title: l10n.notifications,
                        subtitle: l10n.notificationsSubtitle,
                        onTap: () => context.push('/notifications'),
                      ),
                      const SizedBox(height: 18),
                    ],
                    ProfileSectionLabel(label: l10n.preferences),
                    const SizedBox(height: 8),
                    ProfileSegmentedTile(
                      icon: Icons.dark_mode_rounded,
                      iconColor: const Color(0xFF6D28D9),
                      iconBg: const Color(0xFFEDE9FE),
                      title: l10n.appearance,
                      subtitle: l10n.appearanceSubtitle,
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text(l10n.systemTheme),
                            icon: const Icon(Icons.phone_android_rounded, size: 15),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text(l10n.lightTheme),
                            icon: const Icon(Icons.light_mode_rounded, size: 15),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text(l10n.darkTheme),
                            icon: const Icon(Icons.dark_mode_rounded, size: 15),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          ref
                              .read(themeModeProvider.notifier)
                              .updateThemeMode(selection.first);
                        },
                        style: ButtonStyle(
                          textStyle: MaterialStateProperty.all(
                            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    ProfileSegmentedTile(
                      icon: Icons.language_rounded,
                      iconColor: ProfileTheme.blue,
                      iconBg: const Color(0xFFE3F0FC),
                      title: l10n.language,
                      subtitle: l10n.languageSubtitle,
                      child: SegmentedButton<Locale>(
                        segments: [
                          ButtonSegment<Locale>(
                            value: const Locale('en'),
                            label: Text(l10n.english),
                            icon: const Icon(Icons.translate_rounded, size: 15),
                          ),
                          ButtonSegment<Locale>(
                            value: const Locale('ar'),
                            label: Text(l10n.arabic),
                            icon: const Icon(Icons.g_translate_rounded, size: 15),
                          ),
                        ],
                        selected: {Locale(locale.languageCode)},
                        onSelectionChanged: (selection) {
                          ref.read(localeProvider.notifier).updateLocale(selection.first);
                        },
                        style: ButtonStyle(
                          textStyle: MaterialStateProperty.all(
                            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    ProfileNavTile(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF475569),
                      iconBg: const Color(0xFFF1F5F9),
                      title: l10n.account,
                      subtitle: l10n.accountSubtitle,
                      onTap: () => context.push('/profile/account'),
                    ),
                    ProfileNavTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFF475569),
                      iconBg: const Color(0xFFF1F5F9),
                      title: l10n.notifications,
                      subtitle: l10n.notificationsPrefSubtitle,
                      onTap: () => context.push('/notifications'),
                    ),
                    ProfileNavTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF475569),
                      iconBg: const Color(0xFFF1F5F9),
                      title: l10n.helpSupport,
                      subtitle: l10n.helpSupportSubtitle,
                      onTap: () => context.push('/profile/help'),
                    ),
                    const SizedBox(height: 18),
                    ProfileSectionLabel(label: l10n.session),
                    const SizedBox(height: 8),
                    if (!auth.isAuthenticated)
                      ProfileGoldCtaButton(
                        icon: Icons.login_rounded,
                        label: l10n.login,
                        onTap: () => context.go('/login'),
                      )
                    else
                      ProfileDangerTile(
                        icon: Icons.logout_rounded,
                        title: l10n.logout,
                        subtitle: context.tr(
                          'End your current session',
                          'إنهاء جلستك الحالية',
                        ),
                        onTap: () async {
                          final confirmed = await _confirmLogout(context);
                          if (!confirmed || !context.mounted) return;
                          await ref.read(authViewModelProvider.notifier).doLogout();
                          if (!context.mounted) return;
                          context.go('/login');
                        },
                      ),
                    const SizedBox(height: 20),
                    ProfileInfoBanner(text: l10n.compactInfo),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.tr('Sign out?', 'تسجيل الخروج؟'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            context.tr(
              'You will need to sign in again to access your account.',
              'ستحتاج إلى تسجيل الدخول مرة أخرى للوصول إلى حسابك.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: ProfileTheme.dangerFg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('Sign out', 'تسجيل الخروج')),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
