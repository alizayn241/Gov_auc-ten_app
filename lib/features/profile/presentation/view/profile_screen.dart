import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:gov_auction_app/features/auth/presentation/viewmodel/auth_view_model.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/theme_mode_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ProfileHero(
            isAuthenticated: auth.isAuthenticated,
            roleLabel: roleLabel,
            compact: isPhone,
          ),
          const SizedBox(height: 16),
          _QuickStrip(
            items: [
              _QuickStripItem(
                icon: Icons.person_outline,
                label: auth.isAuthenticated ? l10n.activeSession : l10n.guestMode,
              ),
              _QuickStripItem(
                icon: Icons.verified_user_outlined,
                label: roleLabel,
              ),
              _QuickStripItem(
                icon: Icons.phone_iphone_outlined,
                label: l10n.mobileReady,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (auth.isAuthenticated && (isAdmin || isStaff)) ...[
            _SectionCard(
              title: l10n.administration,
              subtitle: l10n.administrationSubtitle,
              children: [
                if (isAdmin)
                  _ActionTile(
                    icon: Icons.dashboard_customize_outlined,
                    title: l10n.adminDashboard,
                    subtitle: l10n.adminDashboardSubtitle,
                    onTap: () => context.push('/admin'),
                  ),
                if (isStaff) ...[
                  _ActionTile(
                    icon: Icons.verified_outlined,
                    title: l10n.approvals,
                    subtitle: l10n.approvalsSubtitle,
                    onTap: () => context.push('/staff/approvals'),
                  ),
                  _ActionTile(
                    icon: Icons.work_outline,
                    title: l10n.processes,
                    subtitle: l10n.processesSubtitle,
                    onTap: () => context.push('/staff/processes'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (auth.isAuthenticated && isCitizen) ...[
            _SectionCard(
              title: l10n.payments,
              subtitle: l10n.paymentsSubtitle,
              children: [
                _ActionTile(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.myPayments,
                  subtitle: l10n.myPaymentsSubtitle,
                  onTap: () => context.push('/my-payments'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.updates,
              subtitle: l10n.updatesSubtitle,
              children: [
                _ActionTile(
                  icon: Icons.notifications_none,
                  title: l10n.notifications,
                  subtitle: l10n.notificationsSubtitle,
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          _SectionCard(
            title: l10n.preferences,
            subtitle: l10n.preferencesSubtitle,
            children: [
              _LanguageTile(
                locale: locale,
                onChanged: (nextLocale) {
                  ref.read(localeProvider.notifier).updateLocale(nextLocale);
                },
              ),
              _ThemeModeTile(
                themeMode: themeMode,
                onChanged: (mode) {
                  ref.read(themeModeProvider.notifier).updateThemeMode(mode);
                },
              ),
              _StaticTile(
                icon: Icons.person_outline,
                title: l10n.account,
                subtitle: l10n.accountSubtitle,
              ),
              _StaticTile(
                icon: Icons.notifications_none,
                title: l10n.notifications,
                subtitle: l10n.notificationsPrefSubtitle,
              ),
              _StaticTile(
                icon: Icons.help_outline,
                title: l10n.helpSupport,
                subtitle: l10n.helpSupportSubtitle,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.session,
            subtitle: auth.isAuthenticated
                ? l10n.sessionSignedIn
                : l10n.sessionSignedOut,
            children: [
              if (!auth.isAuthenticated)
                _PrimaryButton(
                  text: l10n.login,
                  onPressed: () => context.go('/login'),
                )
              else
                _PrimaryButton(
                  text: l10n.logout,
                  onPressed: () async {
                    await ref.read(authViewModelProvider.notifier).doLogout();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          _CompactInfoCard(text: l10n.compactInfo),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final bool isAuthenticated;
  final String roleLabel;
  final bool compact;

  const _ProfileHero({
    required this.isAuthenticated,
    required this.roleLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EntryFlowTokens.backgroundTop, EntryFlowTokens.backgroundBottom],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: EntryFlowTokens.accentWarm,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isAuthenticated ? context.l10n.profileHeroReady : context.l10n.profileHeroGuest,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAuthenticated
                ? context.l10n.profileHeroReadySubtitle
                : context.l10n.profileHeroGuestSubtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(.86),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStripItem {
  final IconData icon;
  final String label;

  const _QuickStripItem({
    required this.icon,
    required this.label,
  });
}

class _QuickStrip extends StatelessWidget {
  final List<_QuickStripItem> items;

  const _QuickStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final primary = Theme.of(context).colorScheme.primary;

          return Container(
            width: 150,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: primary),
                ),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _StaticTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StaticTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeTile({
    required this.themeMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.dark_mode_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appearance,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.appearanceSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text(l10n.systemTheme),
                icon: Icon(Icons.phone_android_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text(l10n.lightTheme),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text(l10n.darkTheme),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) {
              onChanged(selection.first);
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Locale locale;
  final ValueChanged<Locale> onChanged;

  const _LanguageTile({
    required this.locale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.language_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.language,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.languageSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<Locale>(
            segments: [
              ButtonSegment<Locale>(
                value: const Locale('en'),
                label: Text(l10n.english),
                icon: const Icon(Icons.translate_outlined),
              ),
              ButtonSegment<Locale>(
                value: const Locale('ar'),
                label: Text(l10n.arabic),
                icon: const Icon(Icons.g_translate),
              ),
            ],
            selected: {Locale(locale.languageCode)},
            onSelectionChanged: (selection) {
              onChanged(selection.first);
            },
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  final String text;

  const _CompactInfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EntryFlowTokens.backgroundTop,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel, color: EntryFlowTokens.accentWarm),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
