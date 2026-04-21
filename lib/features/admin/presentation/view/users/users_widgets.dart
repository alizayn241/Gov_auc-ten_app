import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';

import 'users_models.dart';

class UsersHero extends StatelessWidget {
  final int totalUsers;
  final int adminCount;
  final int staffCount;
  final int citizenCount;
  final int filteredCount;

  const UsersHero({
    super.key,
    required this.totalUsers,
    required this.adminCount,
    required this.staffCount,
    required this.citizenCount,
    required this.filteredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EntryFlowTokens.backgroundTop,
            EntryFlowTokens.backgroundBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$filteredCount visible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('User Management', 'إدارة المستخدمين'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'Review accounts, update roles, and monitor the platform user base from one place.',
              'راجع الحسابات وحدّث الأدوار وتابع قاعدة مستخدمي المنصة من مكان واحد.',
            ),
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(label: 'Total', value: '$totalUsers'),
              _MetricPill(label: 'Admins', value: '$adminCount'),
              _MetricPill(label: 'Staff', value: '$staffCount'),
              _MetricPill(label: 'Citizens', value: '$citizenCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class UsersToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String filterValue;
  final ValueChanged<String> onFilterChanged;

  const UsersToolbar({
    super.key,
    required this.searchController,
    required this.filterValue,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('User controls', 'عناصر التحكم بالمستخدمين'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Search quickly, then narrow the list by role.',
                'ابحث بسرعة ثم قم بتضييق القائمة حسب الدور.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr(
                  'Search name, email, phone, provider, status, or UID',
                  'ابحث بالاسم أو البريد أو الهاتف أو المزوّد أو الحالة أو المعرّف',
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in const ['All', 'Citizen', 'Staff', 'Admin'])
                  ChoiceChip(
                    label: Text(role),
                    selected: filterValue == role,
                    onSelected: (_) => onFilterChanged(role),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: filterValue == role
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest.withOpacity(.28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                if (searchController.text.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 16),
                    label: Text(context.tr('Clear search', 'مسح البحث')),
                    onPressed: () => searchController.clear(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UsersTable extends StatelessWidget {
  final List<UserRecord> users;
  final String? busyUserId;
  final Future<void> Function(UserRecord user, String role) onRoleChanged;
  final Future<void> Function(UserRecord user) onDisable;
  final Future<void> Function(UserRecord user) onEnable;
  final Future<void> Function(UserRecord user) onDelete;

  const UsersTable({
    super.key,
    required this.users,
    required this.busyUserId,
    required this.onRoleChanged,
    required this.onDisable,
    required this.onEnable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            headingRowHeight: 54,
            dataRowHeight: 56,
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('UID')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Provider')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Joined')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.map((user) {
              final isBusy = busyUserId == user.id;
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(.10),
                          child: Icon(
                            Icons.person_outline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(user.name.isEmpty ? 'Unnamed user' : user.name),
                      ],
                    ),
                  ),
                  DataCell(Text(user.email.isEmpty ? '-' : user.email)),
                  DataCell(SizedBox(width: 200, child: Text(user.id))),
                  DataCell(Text(user.phone.isEmpty ? '-' : user.phone)),
                  DataCell(Text(user.provider)),
                  DataCell(StatusChip(status: user.status)),
                  DataCell(
                    RoleEditor(
                      value: user.role,
                      enabled: !isBusy,
                      onChanged: (value) => onRoleChanged(user, value),
                    ),
                  ),
                  DataCell(Text(user.createdLabel)),
                  DataCell(
                    Row(
                      children: [
                        TextButton(
                          onPressed: isBusy ? null : () => onDisable(user),
                          child: const Text('Disable'),
                        ),
                        TextButton(
                          onPressed: isBusy ? null : () => onEnable(user),
                          child: const Text('Enable'),
                        ),
                        TextButton(
                          onPressed: isBusy ? null : () => onDelete(user),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserRecord user;
  final bool isBusy;
  final Future<void> Function(UserRecord user, String role) onRoleChanged;
  final VoidCallback onDisable;
  final VoidCallback onEnable;
  final VoidCallback onDelete;

  const UserTile({
    super.key,
    required this.user,
    required this.isBusy,
    required this.onRoleChanged,
    required this.onDisable,
    required this.onEnable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(.30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.person_outline, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? 'Unnamed user' : user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email.isEmpty ? 'No email' : user.email,
                          style: TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                  RoleChip(role: user.role),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MiniInfoChip(icon: Icons.shield_outlined, label: user.provider),
                  MiniInfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: user.createdLabel,
                  ),
                  StatusChip(status: user.status),
                ],
              ),
              const SizedBox(height: 14),
              InfoLine(label: 'UID', value: user.id),
              InfoLine(label: 'Phone', value: user.phone.isEmpty ? '-' : user.phone),
              const SizedBox(height: 12),
              RoleEditor(
                value: user.role,
                enabled: !isBusy,
                onChanged: (value) => onRoleChanged(user, value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onDisable,
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Disable'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onEnable,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Enable'),
                  ),
                  TextButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const MiniInfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class RoleEditor extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const RoleEditor({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = switch (value.toLowerCase()) {
      'admin' => 'Admin',
      'staff' => 'Staff',
      _ => 'Citizen',
    };

    return DropdownButton<String>(
      value: normalized,
      items: const [
        DropdownMenuItem(value: 'Citizen', child: Text('Citizen')),
        DropdownMenuItem(value: 'Staff', child: Text('Staff')),
        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
      ],
      onChanged: !enabled
          ? null
          : (next) {
              if (next == null || next == normalized) return;
              onChanged(next);
            },
    );
  }
}

class InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const InfoLine({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class RoleChip extends StatelessWidget {
  final String role;

  const RoleChip({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final lower = role.toLowerCase();
    final color = switch (lower) {
      'admin' => const Color(0xFF0B3C8C),
      'staff' => const Color(0xFF7A5D00),
      _ => Colors.teal,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final color = switch (lower) {
      'active' || 'approved' || 'verified' => const Color(0xFF1F8F63),
      'disabled' || 'suspended' || 'rejected' => const Color(0xFFC54A4A),
      _ => const Color(0xFFD18A1C),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String message;

  const InfoCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF8A6D1D)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF6B5315),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UsersEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const UsersEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
