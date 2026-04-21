import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'shared/admin_shared.dart';
import 'users/users_models.dart';
import 'users/users_widgets.dart';

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
  List<UserRecord> _users = const [];

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
    } catch (_) {}

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

  Future<List<UserRecord>> _loadFromAdminRpc() async {
    final res = await Supabase.instance.client.rpc('admin_list_users');
    if (res is! List) {
      throw Exception('admin_list_users returned an unexpected response');
    }

    return res
        .map((e) => UserRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<UserRecord>> _loadFromProfilesFallback() async {
    final rows = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => UserRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _updateRole(UserRecord user, String role) async {
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
          content: Text(
            context.tr('Role updated to $role', 'تم تحديث الدور إلى $role'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _setDisabled(UserRecord user, bool disabled) async {
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
            '${e.toString().replaceFirst('Exception: ', '')}\nAdd admin_disable_user/admin_enable_user RPCs in Supabase to use this action.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _deleteUser(UserRecord user) async {
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
            '${e.toString().replaceFirst('Exception: ', '')}\nAdd admin_delete_user RPC in Supabase to use this action.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _q.text.trim().toLowerCase();
    final totalUsers = _users.length;
    final adminCount = _users.where((u) => u.role == 'Admin').length;
    final staffCount = _users.where((u) => u.role == 'Staff').length;
    final citizenCount = _users.where((u) => u.role == 'Citizen').length;

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
          UsersHero(
            totalUsers: totalUsers,
            adminCount: adminCount,
            staffCount: staffCount,
            citizenCount: citizenCount,
            filteredCount: items.length,
          ),
          const SizedBox(height: 14),
          UsersToolbar(
            searchController: _q,
            filterValue: _filter,
            onFilterChanged: (v) => setState(() => _filter = v),
          ),
          if (_info != null) ...[
            const SizedBox(height: 12),
            InfoCard(message: _info!),
          ],
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            AdminErrorCard(message: _error!, onRetry: _load)
          else if (items.isEmpty)
            UsersEmptyState(
              title: context.tr('No users found', 'لا يوجد مستخدمون'),
              subtitle: context.tr(
                'Try changing filters or search.',
                'جرّب تغيير عوامل التصفية أو البحث.',
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(
                    '${items.length} users',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Filter: $_filter',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                if (isWide) {
                  return UsersTable(
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
                        (u) => UserTile(
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
