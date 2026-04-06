import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AdminRolesScreen extends StatelessWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _mockRoles();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Roles', 'الأدوار')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HintCard(
            title: context.tr('Role Management', 'إدارة الأدوار'),
            subtitle: context.tr(
              'Define permissions and access control for Citizen / Staff / Admin.',
              'حدد الصلاحيات والتحكم في الوصول للمواطن والموظف والمشرف.',
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((r) => _RoleCard(role: r)).toList(),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HintCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _Role role;
  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(role.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr(
                            'Edit ${role.name} (demo)',
                            'تعديل ${_localizedRoleName(l10n, role.name)} (تجريبي)',
                          ),
                        ),
                      ),
                    ),
                    child: Text(context.tr('Edit', 'تعديل')),
                  )
                ],
              ),
              const SizedBox(height: 10),
              ...role.permissions.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

String _localizedRoleName(AppLocalizations l10n, String roleName) {
  return switch (roleName) {
    'Citizen' => l10n.t('Citizen', 'مواطن'),
    'Staff' => l10n.t('Staff', 'موظف'),
    'Admin' => l10n.t('Admin', 'مشرف'),
    _ => roleName,
  };
}

class _Role {
  final String name;
  final List<String> permissions;
  const _Role(this.name, this.permissions);
}

List<_Role> _mockRoles() => const [
  _Role('Citizen', [
    'Browse auctions/tenders',
    'Place bids',
    'Manage watchlist',
    'Profile management',
  ]),
  _Role('Staff', [
    'Create and manage processes',
    'Review approvals queue',
    'Moderate listings',
    'Generate operational reports',
  ]),
  _Role('Admin', [
    'User & role management',
    'System settings',
    'Audit logs access',
    'Financial reports access',
  ]),
];
