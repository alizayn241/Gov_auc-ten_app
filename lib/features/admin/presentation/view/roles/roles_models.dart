import 'package:gov_auction_app/core/localization/app_localizations.dart';

class AdminRoleItem {
  final String name;
  final List<String> permissions;

  const AdminRoleItem(this.name, this.permissions);
}

List<AdminRoleItem> mockAdminRoles() => const [
  AdminRoleItem('Citizen', [
    'Browse auctions/tenders',
    'Place bids',
    'Manage watchlist',
    'Profile management',
  ]),
  AdminRoleItem('Staff', [
    'Create and manage processes',
    'Review approvals queue',
    'Moderate listings',
    'Generate operational reports',
  ]),
  AdminRoleItem('Admin', [
    'User & role management',
    'System settings',
    'Audit logs access',
    'Financial reports access',
  ]),
];

String localizedRoleName(AppLocalizations l10n, String roleName) {
  return switch (roleName) {
    'Citizen' => l10n.t('Citizen', 'مواطن'),
    'Staff' => l10n.t('Staff', 'موظف'),
    'Admin' => l10n.t('Admin', 'مشرف'),
    _ => roleName,
  };
}
