import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _filter = 'All';
  final _q = TextEditingController();

  bool _loading = true;
  String? _error;
  String? _info;
  String? _busyUserId;
  List<_UserRecord> _users = const [];

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      final users = await _loadFromAdminRpc();

      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
      return;
    } catch (_) {
      // Fall back to profiles below.
    }

    try {
      final users = await _loadFromProfilesFallback();

      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
        _info =
            'Showing users from public profiles only. To view every auth user from Supabase Authentication and use disable/delete actions, add the admin RPC functions on Supabase.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<List<_UserRecord>> _loadFromAdminRpc() async {
    final res = await Supabase.instance.client.rpc('admin_list_users');

    if (res is! List) {
      throw Exception('admin_list_users returned an unexpected response');
    }

    return res
        .map((e) => _UserRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<_UserRecord>> _loadFromProfilesFallback() async {
    final rows = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => _UserRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _updateRole(_UserRecord user, String role) async {
    setState(() => _busyUserId = user.id);

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': user.name.isEmpty ? null : user.name,
        'phone': user.phone.isEmpty ? null : user.phone,
        'role': role.toLowerCase(),
      });

      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Role updated to $role', 'تم تحديث الدور إلى $role')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyUserId = null);
      }
    }
  }

  Future<void> _setDisabled(_UserRecord user, bool disabled) async {
    setState(() => _busyUserId = user.id);

    try {
      await Supabase.instance.client.rpc(
        disabled ? 'admin_disable_user' : 'admin_enable_user',
        params: {'p_user_id': user.id},
      );

      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            disabled
                ? context.tr('User disabled', 'تم تعطيل المستخدم')
                : context.tr('User enabled', 'تم تفعيل المستخدم'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${e.toString().replaceFirst('Exception: ', '')}\n'
            'Add admin_disable_user/admin_enable_user RPCs in Supabase to use this action.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyUserId = null);
      }
    }
  }

  Future<void> _deleteUser(_UserRecord user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Delete User', 'حذف المستخدم')),
        content: Text(
          context.tr(
            'Delete ${user.email.isEmpty ? user.id : user.email} from authentication?',
            'هل تريد حذف ${user.email.isEmpty ? user.id : user.email} من المصادقة؟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Delete', 'حذف')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyUserId = user.id);

    try {
      await Supabase.instance.client.rpc(
        'admin_delete_user',
        params: {'p_user_id': user.id},
      );

      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('User deleted', 'تم حذف المستخدم'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${e.toString().replaceFirst('Exception: ', '')}\n'
            'Add admin_delete_user RPC in Supabase to use this action.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _q.text.trim().toLowerCase();
    final items = _users.where((u) {
      if (_filter != 'All' && u.role.toLowerCase() != _filter.toLowerCase()) {
        return false;
      }
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.phone.toLowerCase().contains(query) ||
          u.provider.toLowerCase().contains(query) ||
          u.status.toLowerCase().contains(query) ||
          u.id.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Users', 'المستخدمون')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Toolbar(
            searchController: _q,
            filterValue: _filter,
            onFilterChanged: (v) => setState(() => _filter = v),
          ),
          if (_info != null) ...[
            const SizedBox(height: 12),
            _InfoCard(message: _info!),
          ],
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _load)
          else if (items.isEmpty)
            _Empty(
              title: context.tr('No users found', 'لا يوجد مستخدمون'),
              subtitle: context.tr(
                'Try changing filters or search.',
                'جرّب تغيير عوامل التصفية أو البحث.',
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${items.length} users',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                if (isWide) {
                  return _UsersTable(
                    users: items,
                    busyUserId: _busyUserId,
                    onRoleChanged: _updateRole,
                    onDisable: (user) => _setDisabled(user, true),
                    onEnable: (user) => _setDisabled(user, false),
                    onDelete: _deleteUser,
                  );
                }

                return Column(
                  children: items
                      .map(
                        (u) => _UserTile(
                          user: u,
                          isBusy: _busyUserId == u.id,
                          onRoleChanged: _updateRole,
                          onDisable: () => _setDisabled(u, true),
                          onEnable: () => _setDisabled(u, false),
                          onDelete: () => _deleteUser(u),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String filterValue;
  final ValueChanged<String> onFilterChanged;

  const _Toolbar({
    required this.searchController,
    required this.filterValue,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: context.tr(
                  'Search name, email, phone, provider, status, or UID',
                  'ابحث بالاسم أو البريد أو الهاتف أو المزوّد أو الحالة أو المعرف',
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                Text(context.tr('Role:', 'الدور:')),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: filterValue,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Citizen', child: Text('Citizen')),
                    DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => onFilterChanged(v ?? 'All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<_UserRecord> users;
  final String? busyUserId;
  final Future<void> Function(_UserRecord user, String role) onRoleChanged;
  final Future<void> Function(_UserRecord user) onDisable;
  final Future<void> Function(_UserRecord user) onEnable;
  final Future<void> Function(_UserRecord user) onDelete;

  const _UsersTable({
    required this.users,
    required this.busyUserId,
    required this.onRoleChanged,
    required this.onDisable,
    required this.onEnable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
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
                DataCell(Text(user.name.isEmpty ? 'Unnamed user' : user.name)),
                DataCell(Text(user.email.isEmpty ? '-' : user.email)),
                DataCell(SizedBox(width: 200, child: Text(user.id))),
                DataCell(Text(user.phone.isEmpty ? '-' : user.phone)),
                DataCell(Text(user.provider)),
                DataCell(Text(user.status)),
                DataCell(
                  _RoleEditor(
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
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
    );
  }
}

class _UserTile extends StatelessWidget {
  final _UserRecord user;
  final bool isBusy;
  final Future<void> Function(_UserRecord user, String role) onRoleChanged;
  final VoidCallback onDisable;
  final VoidCallback onEnable;
  final VoidCallback onDelete;

  const _UserTile({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primary.withOpacity(.12),
                    child: Icon(Icons.person, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? 'Unnamed user' : user.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email.isEmpty ? 'No email' : user.email,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoleChip(role: user.role),
                ],
              ),
              const SizedBox(height: 12),
              _InfoLine(label: 'UID', value: user.id),
              _InfoLine(label: 'Phone', value: user.phone.isEmpty ? '-' : user.phone),
              _InfoLine(label: 'Provider', value: user.provider),
              _InfoLine(label: 'Status', value: user.status),
              _InfoLine(label: 'Joined', value: user.createdLabel),
              const SizedBox(height: 12),
              _RoleEditor(
                value: user.role,
                enabled: !isBusy,
                onChanged: (value) => onRoleChanged(user, value),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: isBusy ? null : onDisable,
                    child: const Text('Disable'),
                  ),
                  OutlinedButton(
                    onPressed: isBusy ? null : onEnable,
                    child: const Text('Enable'),
                  ),
                  TextButton(
                    onPressed: isBusy ? null : onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
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

class _RoleEditor extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _RoleEditor({
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

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

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

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Retry', 'إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String message;
  const _InfoCard({required this.message});

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

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Empty({required this.title, required this.subtitle});

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

class _UserRecord {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String provider;
  final String status;
  final DateTime? createdAt;

  const _UserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.provider,
    required this.status,
    required this.createdAt,
  });

  factory _UserRecord.fromMap(Map<String, dynamic> map) {
    final resolvedName = _firstNonEmpty([
      map['display_name'],
      map['name'],
      map['full_name'],
      map['username'],
      map['email'],
      map['id'],
    ]);

    return _UserRecord(
      id: _firstNonEmpty([map['user_id'], map['id']]),
      name: resolvedName,
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: _normalizeRole((map['role'] ?? 'Citizen').toString()),
      provider: _firstNonEmpty([
        map['provider'],
        map['providers'],
        map['provider_type'],
        'Email',
      ]),
      status: _firstNonEmpty([
        map['status'],
        map['kyc_status'],
        map['auth_status'],
        'unknown',
      ]),
      createdAt: DateTime.tryParse(
        _firstNonEmpty([map['created_at'], map['last_sign_in_at']]),
      )?.toLocal(),
    );
  }

  String get createdLabel {
    final d = createdAt;
    if (d == null) return '-';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _normalizeRole(String value) {
    return switch (value.toLowerCase()) {
      'admin' => 'Admin',
      'staff' => 'Staff',
      _ => 'Citizen',
    };
  }
}
