import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  _DashboardMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        sb.from('profiles').select('id,display_name,created_at'),
        sb.from('auctions').select('id,status,end_time'),
        sb.from('tenders').select('id,status,submission_deadline'),
        sb
            .from('auction_participants')
            .select('user_id,status,created_at,auction_id'),
        sb
            .from('tender_participants')
            .select('vendor_id,status,created_at,tender_id'),
        sb.from('payments').select('id,amount,status,created_at'),
      ]);

      final profiles = _asRows(results[0]);
      final auctions = _asRows(results[1]);
      final tenders = _asRows(results[2]);
      final auctionParticipants = _asRows(results[3]);
      final tenderParticipants = _asRows(results[4]);
      final payments = _asRows(results[5]);

      final newUsers = profiles.where((row) {
        final createdAt = _parseDate(row['created_at']);
        return createdAt != null && !createdAt.isBefore(thirtyDaysAgo);
      }).length;

      final activeAuctions = auctions.where((row) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        final endTime = _parseDate(row['end_time']);
        final byTime = endTime != null && endTime.isAfter(now);
        final byStatus = {
          'active',
          'published',
          'live',
          'awaiting_payment'
        }.contains(status);
        return byTime || byStatus;
      }).length;

      final activeTenders = tenders.where((row) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        final deadline = _parseDate(row['submission_deadline']);
        final byTime = deadline != null && deadline.isAfter(now);
        final byStatus =
            !{'closed', 'cancelled', 'awarded'}.contains(status);
        return byTime || byStatus;
      }).length;

      final pendingAuctionApprovals = auctionParticipants.where((row) {
        return (row['status'] ?? '').toString().toLowerCase() == 'pending';
      }).length;

      final pendingTenderApprovals = tenderParticipants.where((row) {
        return (row['status'] ?? '').toString().toLowerCase() == 'pending';
      }).length;

      final paymentsThisMonth = payments.fold<double>(0, (sum, row) {
        final createdAt = _parseDate(row['created_at']);
        final status = (row['status'] ?? '').toString().toLowerCase();
        if (createdAt == null ||
            createdAt.isBefore(startOfMonth) ||
            status != 'paid') {
          return sum;
        }
        return sum + _toDouble(row['amount']);
      });

      final activity = <_ActivityItem>[
        ...profiles
            .where((row) => _parseDate(row['created_at']) != null)
            .map(
              (row) => _ActivityItem(
                sortAt: _parseDate(row['created_at'])!,
                title: 'New user registered',
                subtitle: '${_displayName(row)} joined the platform',
              ),
            ),
        ...auctionParticipants
            .where((row) => _parseDate(row['created_at']) != null)
            .map(
              (row) => _ActivityItem(
                sortAt: _parseDate(row['created_at'])!,
                title:
                    '${_titleCase((row['status'] ?? 'pending').toString())} auction approval',
                subtitle: 'Auction ${row['auction_id']} | User ${row['user_id']}',
              ),
            ),
        ...tenderParticipants
            .where((row) => _parseDate(row['created_at']) != null)
            .map(
              (row) => _ActivityItem(
                sortAt: _parseDate(row['created_at'])!,
                title:
                    '${_titleCase((row['status'] ?? 'pending').toString())} tender approval',
                subtitle:
                    'Tender ${row['tender_id']} | Vendor ${row['vendor_id']}',
              ),
            ),
        ...payments
            .where((row) => _parseDate(row['created_at']) != null)
            .map(
              (row) => _ActivityItem(
                sortAt: _parseDate(row['created_at'])!,
                title: 'Payment recorded',
                subtitle:
                    'Payment ${row['id']} | EGP ${_toDouble(row['amount']).toStringAsFixed(0)}',
              ),
            ),
      ]..sort((a, b) => b.sortAt.compareTo(a.sortAt));

      if (!mounted) return;
      setState(() {
        _metrics = _DashboardMetrics(
          activeProcesses: activeAuctions + activeTenders,
          newUsersLast30Days: newUsers,
          pendingApprovals:
              pendingAuctionApprovals + pendingTenderApprovals,
          paymentsThisMonth: paymentsThisMonth,
          recentActivity: activity.take(3).toList(),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metrics = _metrics;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Admin Dashboard', 'لوحة الإدارة')),
        leading: IconButton(
          tooltip: context.tr('Back', 'رجوع'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderBanner(
            title: context.tr('Government Admin Console', 'لوحة الإدارة الحكومية'),
            subtitle: context.tr(
              'Manage system overview, roles, processes, and platform settings.',
              'إدارة نظرة عامة على النظام والأدوار والعمليات وإعدادات المنصة.',
            ),
            actionText: context.tr('View Reports', 'عرض التقارير'),
            onAction: () => context.push('/admin/reports'),
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 900;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: wide ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: wide ? 1.45 : 1.20,
                ),
                children: [
                  _KpiCard(
                    icon: Icons.gavel,
                    title: context.tr('Active Processes', 'العمليات النشطة'),
                    value: metrics == null ? '...' : '${metrics.activeProcesses}',
                    hint: context.tr('Live auctions + tenders', 'المزادات والمناقصات الجارية'),
                  ),
                  _KpiCard(
                    icon: Icons.how_to_reg,
                    title: context.tr('New Users', 'المستخدمون الجدد'),
                    value: metrics == null
                        ? '...'
                        : '${metrics.newUsersLast30Days}',
                    hint: context.tr('Last 30 days', 'آخر 30 يوماً'),
                  ),
                  _KpiCard(
                    icon: Icons.approval,
                    title: context.tr('Pending Approvals', 'الموافقات المعلقة'),
                    value:
                        metrics == null ? '...' : '${metrics.pendingApprovals}',
                    hint: context.tr('Auction + tender reviews', 'مراجعات المزادات والمناقصات'),
                    highlight: true,
                  ),
                  _KpiCard(
                    icon: Icons.payments_outlined,
                    title: context.tr('Payments', 'المدفوعات'),
                    value: metrics == null
                        ? '...'
                        : 'EGP ${metrics.paymentsThisMonth.toStringAsFixed(0)}',
                    hint: context.tr('Paid this month', 'المدفوع هذا الشهر'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('Quick Actions', 'إجراءات سريعة'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 900;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.45 : 1.20,
                children: [
                  _ActionCard(
                    icon: Icons.add_business_outlined,
                    title: 'Create Auction',
                    subtitle: 'Create new government auction',
                    onTap: () => context.push('/admin/auctions/create'),
                  ),
                  _ActionCard(
                    icon: Icons.playlist_add_circle_outlined,
                    title: 'Create Tender',
                    subtitle: 'Publish a new government tender',
                    onTap: () => context.push('/admin/tenders/create'),
                  ),
                  _ActionCard(
                    icon: Icons.groups_2_outlined,
                    title: 'Users',
                    subtitle: 'Manage citizens / staff / admins',
                    onTap: () => context.push('/admin/users'),
                  ),
                  _ActionCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Roles',
                    subtitle: 'Citizen | Staff | Admin',
                    onTap: () => context.push('/admin/roles'),
                  ),
                  _ActionCard(
                    icon: Icons.rule_folder_outlined,
                    title: 'Processes',
                    subtitle: 'Auction / Tender lifecycle',
                    onTap: () => context.push('/admin/processes'),
                  ),
                  _ActionCard(
                    icon: Icons.request_quote_outlined,
                    title: 'Tenders',
                    subtitle: 'Manage tenders & awards',
                    onTap: () => context.push('/admin/tenders'),
                  ),
                  _ActionCard(
                    icon: Icons.description_outlined,
                    title: 'Contracts',
                    subtitle: 'Create & manage contracts',
                    onTap: () => context.push('/admin/contracts'),
                  ),
                  _ActionCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    subtitle: 'Templates & delivery status',
                    onTap: () => context.push('/admin/notifications'),
                  ),
                  _ActionCard(
                    icon: Icons.security_outlined,
                    title: 'Audit Logs',
                    subtitle: 'Transparency & traceability',
                    onTap: () => context.push('/admin/audit-logs'),
                  ),
                  _ActionCard(
                    icon: Icons.settings_outlined,
                    title: 'System Settings',
                    subtitle: 'Branding & configurations',
                    onTap: () => context.push('/admin/settings'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timeline_outlined),
                      SizedBox(width: 8),
                      Text(
                        'Recent Activity',
                        style:
                            TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_loading && metrics == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (metrics == null || metrics.recentActivity.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No recent activity available.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._buildActivityRows(metrics.recentActivity),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/admin/reports'),
                      child: Text(
                        'View reports',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityRows(List<_ActivityItem> items) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      widgets.add(
        _ActivityRow(
          title: item.title,
          subtitle: item.subtitle,
          time: _relativeTime(item.sortAt),
        ),
      );
      if (i != items.length - 1) {
        widgets.add(const Divider(height: 18));
      }
    }
    return widgets;
  }

  static List<Map<String, dynamic>> _asRows(dynamic response) {
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static String _displayName(Map<String, dynamic> row) {
    final name = (row['display_name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final id = (row['id'] ?? '').toString();
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  static String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

class _DashboardMetrics {
  final int activeProcesses;
  final int newUsersLast30Days;
  final int pendingApprovals;
  final double paymentsThisMonth;
  final List<_ActivityItem> recentActivity;

  const _DashboardMetrics({
    required this.activeProcesses,
    required this.newUsersLast30Days,
    required this.pendingApprovals,
    required this.paymentsThisMonth,
    required this.recentActivity,
  });
}

class _ActivityItem {
  final DateTime sortAt;
  final String title;
  final String subtitle;

  const _ActivityItem({
    required this.sortAt,
    required this.title,
    required this.subtitle,
  });
}

class _HeaderBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const _HeaderBanner({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 520;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: isWide
              ? Row(
                  children: [
                    const Icon(Icons.account_balance,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BannerText(title: title, subtitle: subtitle),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 40,
                      child: FilledButton(
                        onPressed: onAction,
                        child: Text(actionText),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance,
                            color: Colors.white, size: 30),
                        SizedBox(width: 10),
                        Text(
                          'Government Admin Console',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton(
                        onPressed: onAction,
                        child: Text(actionText),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _BannerText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BannerText({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, height: 1.3),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String hint;
  final bool highlight;

  const _KpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.hint,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = const Color(0xFFFDC32D);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (highlight ? accent : primary.withOpacity(.10)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                color: highlight ? Colors.black : primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 10, color: Color(0xFF0B3C8C)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}
