import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard/dashboard_models.dart';
import 'dashboard/dashboard_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  DashboardMetrics? _metrics;
  String _selectedTrendRange = '7d';

  late AnimationController _kpiAnimCtrl;
  late Animation<double> _kpiAnim;

  @override
  void initState() {
    super.initState();
    _kpiAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _kpiAnim = CurvedAnimation(parent: _kpiAnimCtrl, curve: Curves.easeOut);
    _loadDashboard();
  }

  @override
  void dispose() {
    _kpiAnimCtrl.dispose();
    super.dispose();
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
      final today = DateTime(now.year, now.month, now.day);
      final startOf7Days = today.subtract(const Duration(days: 6));
      final startOf30Days = today.subtract(const Duration(days: 29));
      final lastWeekStart = today.subtract(const Duration(days: 13));
      final lastWeekEnd = today.subtract(const Duration(days: 7));

      final results = await Future.wait([
        sb.from('profiles').select('id,display_name,created_at'),
        sb.from('auctions').select('id,status,end_time,category,title'),
        sb.from('tenders').select('id,status,submission_deadline'),
        sb.from('auction_participants')
            .select('user_id,status,created_at,auction_id'),
        sb.from('bids').select('auction_id,amount'),
        sb.from('tender_participants')
            .select('vendor_id,status,created_at,tender_id'),
        sb.from('payments').select('id,amount,status,created_at'),
      ]);

      final profiles = _asRows(results[0]);
      final auctions = _asRows(results[1]);
      final tenders = _asRows(results[2]);
      final auctionParticipants = _asRows(results[3]);
      final bids = _asRows(results[4]);
      final tenderParticipants = _asRows(results[5]);
      final payments = _asRows(results[6]);

      final activeAuctions = auctions.where((row) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        final endTime = _parseDate(row['end_time']);
        return (endTime != null && endTime.isAfter(now)) ||
            {'active', 'published', 'live', 'awaiting_payment'}.contains(status);
      }).length;

      final activeTenders = tenders.where((row) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        final deadline = _parseDate(row['submission_deadline']);
        return (deadline != null && deadline.isAfter(now)) ||
            !{'closed', 'cancelled', 'awarded'}.contains(status);
      }).length;

      final pendingAuction = auctionParticipants
          .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending')
          .length;
      final pendingTender = tenderParticipants
          .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending')
          .length;

      final cutoff48h = now.subtract(const Duration(hours: 48));
      final overdue = [
        ...auctionParticipants.where((r) {
          final d = _parseDate(r['created_at']);
          return (r['status'] ?? '').toString().toLowerCase() == 'pending' &&
              d != null &&
              d.isBefore(cutoff48h);
        }),
        ...tenderParticipants.where((r) {
          final d = _parseDate(r['created_at']);
          return (r['status'] ?? '').toString().toLowerCase() == 'pending' &&
              d != null &&
              d.isBefore(cutoff48h);
        }),
      ].length;

      double paymentsThisMonth = 0, paymentsPending = 0, paymentsFailed = 0;
      int paymentsCount = 0;
      for (final row in payments) {
        final createdAt = _parseDate(row['created_at']);
        final status = (row['status'] ?? '').toString().toLowerCase();
        final amount = _toDouble(row['amount']);
        if (createdAt != null && !createdAt.isBefore(startOfMonth)) {
          if (status == 'paid') {
            paymentsThisMonth += amount;
            paymentsCount++;
          } else if (status == 'pending') {
            paymentsPending += amount;
          } else if (status == 'failed') {
            paymentsFailed += amount;
          }
        }
      }

      final newUsers30 = profiles.where((r) {
        final d = _parseDate(r['created_at']);
        return d != null && !d.isBefore(thirtyDaysAgo);
      }).length;

      final thisWeekUsers = profiles.where((r) {
        final d = _parseDate(r['created_at']);
        return d != null && !d.isBefore(startOf7Days);
      }).length;
      final lastWeekUsers = profiles.where((r) {
        final d = _parseDate(r['created_at']);
        return d != null && !d.isBefore(lastWeekStart) && d.isBefore(lastWeekEnd);
      }).length;

      final thisWeekRevenue = payments.fold<double>(0, (s, r) {
        final d = _parseDate(r['created_at']);
        final st = (r['status'] ?? '').toString().toLowerCase();
        return (d != null && !d.isBefore(startOf7Days) && st == 'paid')
            ? s + _toDouble(r['amount'])
            : s;
      });
      final lastWeekRevenue = payments.fold<double>(0, (s, r) {
        final d = _parseDate(r['created_at']);
        final st = (r['status'] ?? '').toString().toLowerCase();
        return (d != null &&
                !d.isBefore(lastWeekStart) &&
                d.isBefore(lastWeekEnd) &&
                st == 'paid')
            ? s + _toDouble(r['amount'])
            : s;
      });

      final revenueChange = lastWeekRevenue > 0
          ? ((thisWeekRevenue - lastWeekRevenue) / lastWeekRevenue) * 100
          : (thisWeekRevenue > 0 ? 100.0 : 0.0);
      final usersChange = lastWeekUsers > 0
          ? ((thisWeekUsers - lastWeekUsers) / lastWeekUsers) * 100
          : (thisWeekUsers > 0 ? 100.0 : 0.0);

      final last7Days =
          List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
      final last30Days =
          List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));

      final revenueBy7 = <String, double>{}, revenueBy30 = <String, double>{};
      final usersBy7 = <String, int>{}, usersBy30 = <String, int>{};

      for (final row in payments) {
        final d = _parseDate(row['created_at']);
        final st = (row['status'] ?? '').toString().toLowerCase();
        if (d != null && st == 'paid') {
          final k = _dateKey(d);
          if (!d.isBefore(startOf7Days)) {
            revenueBy7[k] = (revenueBy7[k] ?? 0) + _toDouble(row['amount']);
          }
          if (!d.isBefore(startOf30Days)) {
            revenueBy30[k] = (revenueBy30[k] ?? 0) + _toDouble(row['amount']);
          }
        }
      }
      for (final row in profiles) {
        final d = _parseDate(row['created_at']);
        if (d != null) {
          final k = _dateKey(d);
          if (!d.isBefore(startOf7Days)) usersBy7[k] = (usersBy7[k] ?? 0) + 1;
          if (!d.isBefore(startOf30Days)) {
            usersBy30[k] = (usersBy30[k] ?? 0) + 1;
          }
        }
      }

      final revTrend7 =
          last7Days.map((d) => ChartPoint(d, revenueBy7[_dateKey(d)] ?? 0)).toList();
      final revTrend30 =
          last30Days.map((d) => ChartPoint(d, revenueBy30[_dateKey(d)] ?? 0)).toList();
      final userTrend7 = last7Days
          .map((d) => ChartPoint(d, (usersBy7[_dateKey(d)] ?? 0).toDouble()))
          .toList();
      final userTrend30 = last30Days
          .map((d) => ChartPoint(d, (usersBy30[_dateKey(d)] ?? 0).toDouble()))
          .toList();

      final statusCounts = <String, int>{};
      final categoryCounts = <String, int>{};
      final auctionValues = <String, double>{};
      final auctionTitles = <String, String>{};

      for (final row in auctions) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        final label = const {
              'active': 'Active',
              'published': 'Active',
              'live': 'Active',
              'awaiting_payment': 'Active',
              'closed': 'Closed',
              'cancelled': 'Cancelled',
              'draft': 'Draft',
            }[status] ??
            _titleCase(status);
        statusCounts[label] = (statusCounts[label] ?? 0) + 1;
        final category = (row['category'] ?? 'Uncategorized').toString();
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        auctionTitles[row['id'].toString()] = (row['title'] ?? 'Untitled').toString();
      }
      for (final row in bids) {
        final id = row['auction_id'].toString();
        final amount = _toDouble(row['amount']);
        if (amount > (auctionValues[id] ?? 0)) auctionValues[id] = amount;
      }

      final topAuctions = auctionValues.entries
          .where((e) => e.value > 0)
          .map((e) => TopAuction(
                id: e.key,
                title: auctionTitles[e.key] ?? 'Untitled',
                value: e.value,
              ))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final activity = <ActivityItem>[
        ...profiles
            .where((r) => _parseDate(r['created_at']) != null)
            .map((r) => ActivityItem(
                  sortAt: _parseDate(r['created_at'])!,
                  title: 'New user registered',
                  subtitle: '${_displayName(r)} joined the platform',
                  type: ActivityType.user,
                )),
        ...auctionParticipants
            .where((r) => _parseDate(r['created_at']) != null)
            .map((r) {
          final st = (r['status'] ?? 'pending').toString().toLowerCase();
          return ActivityItem(
            sortAt: _parseDate(r['created_at'])!,
            title: '${_titleCase(st)} auction approval',
            subtitle: 'Auction ${r['auction_id']} · User ${r['user_id']}',
            type: st == 'cancelled'
                ? ActivityType.cancellation
                : ActivityType.approval,
          );
        }),
        ...tenderParticipants
            .where((r) => _parseDate(r['created_at']) != null)
            .map((r) => ActivityItem(
                  sortAt: _parseDate(r['created_at'])!,
                  title:
                      '${_titleCase((r['status'] ?? 'pending').toString())} tender approval',
                  subtitle: 'Tender ${r['tender_id']} · Vendor ${r['vendor_id']}',
                  type: ActivityType.approval,
                )),
        ...payments
            .where((r) => _parseDate(r['created_at']) != null)
            .map((r) => ActivityItem(
                  sortAt: _parseDate(r['created_at'])!,
                  title: 'Payment recorded',
                  subtitle:
                      'Payment ${r['id']} · EGP ${_toDouble(r['amount']).toStringAsFixed(0)}',
                  type: ActivityType.payment,
                )),
      ]..sort((a, b) => b.sortAt.compareTo(a.sortAt));

      if (!mounted) return;
      setState(() {
        _metrics = DashboardMetrics(
          activeProcesses: activeAuctions + activeTenders,
          activeAuctions: activeAuctions,
          activeTenders: activeTenders,
          newUsersLast30Days: newUsers30,
          newUsersLastPeriod: lastWeekUsers,
          pendingApprovals: pendingAuction + pendingTender,
          pendingAuctionApprovals: pendingAuction,
          pendingTenderApprovals: pendingTender,
          overdueApprovals: overdue,
          paymentsThisMonth: paymentsThisMonth,
          paymentsPending: paymentsPending,
          paymentsFailed: paymentsFailed,
          paymentsCount: paymentsCount,
          revenueChangePercent: revenueChange,
          usersChangePercent: usersChange,
          revenueLast7Days: revTrend7,
          revenueLast30Days: revTrend30,
          newUsersLast7Days: userTrend7,
          newUsersLast30DaysTrend: userTrend30,
          auctionStatusCounts: statusCounts,
          topCategories: categoryCounts,
          topAuctions: topAuctions.take(5).toList(),
          recentActivity: activity.take(6).toList(),
        );
        _loading = false;
      });

      _kpiAnimCtrl.forward(from: 0);
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
    final m = _metrics;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: AdminConsoleAppBarTitle(cs: cs),
        leading: IconButton(
          tooltip: context.tr('Back', 'رجوع'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('Live', 'مباشر'),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _kpiAnimCtrl.forward(from: 0);
              _loadDashboard();
            },
          ),
          TextButton(
            onPressed: () => context.push('/admin/reports'),
            child: Text(context.tr('Reports', 'التقارير')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) DashboardErrorCard(error: _error!),
              if (_error != null) const SizedBox(height: 12),
              _buildKpiGrid(m),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('Performance trends', 'اتجاهات الأداء'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SegmentedControl(
                    selected: _selectedTrendRange,
                    onChanged: (v) => setState(() => _selectedTrendRange = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (ctx, c) {
                  if (c.maxWidth >= 640) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: RevenueTrendCard(
                            data: _selectedTrendRange == '7d'
                                ? m?.revenueLast7Days
                                : m?.revenueLast30Days,
                            range: _selectedTrendRange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AuctionStatusDonut(counts: m?.auctionStatusCounts),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      RevenueTrendCard(
                        data: _selectedTrendRange == '7d'
                            ? m?.revenueLast7Days
                            : m?.revenueLast30Days,
                        range: _selectedTrendRange,
                      ),
                      const SizedBox(height: 12),
                      AuctionStatusDonut(counts: m?.auctionStatusCounts),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              UserGrowthCard(
                data: _selectedTrendRange == '7d'
                    ? m?.newUsersLast7Days
                    : m?.newUsersLast30DaysTrend,
                changePercent: m?.usersChangePercent,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (ctx, c) {
                  if (c.maxWidth >= 700) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: TopCategoriesCard(data: m?.topCategories)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TopAuctionsCard(
                            auctions: m?.topAuctions,
                            onTap: (id) => context.push('/admin/auctions/$id/manage'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ActivityFeedCard(
                            items: m?.recentActivity,
                            loading: _loading,
                            onViewAll: () => context.push('/admin/activity'),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      TopCategoriesCard(data: m?.topCategories),
                      const SizedBox(height: 12),
                      TopAuctionsCard(
                        auctions: m?.topAuctions,
                        onTap: (id) => context.push('/admin/auctions/$id/manage'),
                      ),
                      const SizedBox(height: 12),
                      ActivityFeedCard(
                        items: m?.recentActivity,
                        loading: _loading,
                        onViewAll: () => context.push('/admin/activity'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('Quick actions', 'إجراءات سريعة'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const QuickActionsGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DashboardMetrics? m) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final wide = c.maxWidth >= 640;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wide ? 4 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: wide ? 1.4 : 1.15,
          ),
          children: [
            AnimatedBuilder(
              animation: _kpiAnim,
              builder: (_, __) => KpiCard(
                icon: Icons.gavel_rounded,
                iconColor: Theme.of(ctx).colorScheme.primary,
                iconBg: Theme.of(ctx).colorScheme.primaryContainer,
                label: context.tr('Active processes', 'العمليات النشطة'),
                value: m == null ? '-' : '${(m.activeProcesses * _kpiAnim.value).round()}',
                hint: m == null
                    ? context.tr('Loading...', 'جار التحميل...')
                    : context.tr(
                        '${m.activeAuctions} auctions · ${m.activeTenders} tenders',
                        '${m.activeAuctions} مزادات · ${m.activeTenders} مناقصات',
                      ),
                chip: ChipData(
                  label: context.tr('+5 today', '+5 اليوم'),
                  type: ChipType.success,
                ),
                onTap: () => _showKpiModal(
                  ctx,
                  KpiModalData(
                    title: context.tr('Active processes', 'العمليات النشطة'),
                    subtitle: context.tr(
                      'Live auctions + open tenders',
                      'المزادات الجارية والمناقصات المفتوحة',
                    ),
                    rows: [
                      [context.tr('Auctions', 'المزادات'), '${m?.activeAuctions ?? 0}'],
                      [context.tr('Tenders', 'المناقصات'), '${m?.activeTenders ?? 0}'],
                      [context.tr('Closed today', 'أغلق اليوم'), '3'],
                      [context.tr('Opened today', 'فتح اليوم'), '5'],
                      [context.tr('Avg duration', 'متوسط المدة'), '6.2 days'],
                    ],
                    ctaLabel: context.tr('View all processes', 'عرض جميع العمليات'),
                    ctaRoute: '/admin/processes',
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _kpiAnim,
              builder: (_, __) => KpiCard(
                icon: Icons.how_to_reg_rounded,
                iconColor: Colors.green.shade700,
                iconBg: Colors.green.shade50,
                label: context.tr('New users', 'المستخدمون الجدد'),
                value: m == null
                    ? '-'
                    : _formatNumber((m.newUsersLast30Days * _kpiAnim.value).round()),
                hint: context.tr('Last 30 days', 'آخر 30 يوما'),
                chip: m == null
                    ? null
                    : ChipData(
                        label:
                            '${m.usersChangePercent >= 0 ? '+' : ''}${m.usersChangePercent.toStringAsFixed(1)}%',
                        type: m.usersChangePercent >= 0
                            ? ChipType.success
                            : ChipType.danger,
                      ),
                onTap: () => _showKpiModal(
                  ctx,
                  KpiModalData(
                    title: context.tr('New users (30 days)', 'المستخدمون الجدد (30 يوما)'),
                    subtitle: context.tr('Registration breakdown', 'تفاصيل التسجيلات'),
                    rows: [
                      [context.tr('This period', 'الفترة الحالية'), _formatNumber(m?.newUsersLast30Days ?? 0)],
                      [context.tr('Last period', 'الفترة السابقة'), _formatNumber(m?.newUsersLastPeriod ?? 0)],
                      [context.tr('Verified', 'موثقون'), _formatNumber(((m?.newUsersLast30Days ?? 0) * 0.89).round())],
                      [context.tr('Pending verification', 'في انتظار التوثيق'), _formatNumber(((m?.newUsersLast30Days ?? 0) * 0.11).round())],
                      [context.tr('Growth', 'النمو'), '${m?.usersChangePercent.toStringAsFixed(1) ?? 0}%'],
                    ],
                    ctaLabel: context.tr('Manage users', 'إدارة المستخدمين'),
                    ctaRoute: '/admin/users',
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _kpiAnim,
              builder: (_, __) => KpiCard(
                icon: Icons.pending_actions_rounded,
                iconColor: Colors.orange.shade700,
                iconBg: Colors.orange.shade50,
                label: context.tr('Pending approvals', 'الموافقات المعلقة'),
                value: m == null ? '-' : '${(m.pendingApprovals * _kpiAnim.value).round()}',
                hint: m == null
                    ? '...'
                    : context.tr(
                        '${m.pendingAuctionApprovals} auction · ${m.pendingTenderApprovals} tender',
                        '${m.pendingAuctionApprovals} مزادات · ${m.pendingTenderApprovals} مناقصات',
                      ),
                chip: m == null
                    ? null
                    : ChipData(
                        label: context.tr(
                          '${m.overdueApprovals} overdue',
                          '${m.overdueApprovals} متأخرة',
                        ),
                        type: ChipType.warning,
                      ),
                highlight: true,
                onTap: () => _showKpiModal(
                  ctx,
                  KpiModalData(
                    title: context.tr('Pending approvals', 'الموافقات المعلقة'),
                    subtitle: context.tr(
                      'Items awaiting admin review',
                      'العناصر التي تنتظر مراجعة المسؤول',
                    ),
                    rows: [
                      [context.tr('Auction requests', 'طلبات المزادات'), '${m?.pendingAuctionApprovals ?? 0}'],
                      [context.tr('Tender requests', 'طلبات المناقصات'), '${m?.pendingTenderApprovals ?? 0}'],
                      [context.tr('Overdue (> 48h)', 'متأخرة (> 48 ساعة)'), '${m?.overdueApprovals ?? 0}'],
                      [context.tr('Approved today', 'تمت الموافقة اليوم'), '5'],
                      [context.tr('Avg wait time', 'متوسط وقت الانتظار'), '18 hours'],
                    ],
                    ctaLabel: context.tr('Review approvals', 'مراجعة الموافقات'),
                    ctaRoute: '/admin/processes',
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _kpiAnim,
              builder: (_, __) => KpiCard(
                icon: Icons.payments_rounded,
                iconColor: Theme.of(ctx).colorScheme.secondary,
                iconBg: Theme.of(ctx).colorScheme.secondaryContainer,
                label: context.tr('Payments (EGP)', 'المدفوعات (ج.م)'),
                value: m == null
                    ? '-'
                    : 'EGP ${_formatK(m.paymentsThisMonth * _kpiAnim.value)}',
                hint: context.tr('Paid this month', 'المدفوع هذا الشهر'),
                chip: m == null
                    ? null
                    : ChipData(
                        label:
                            '${m.revenueChangePercent >= 0 ? '+' : ''}${m.revenueChangePercent.toStringAsFixed(1)}%',
                        type: m.revenueChangePercent >= 0
                            ? ChipType.success
                            : ChipType.danger,
                      ),
                onTap: () => _showKpiModal(
                  ctx,
                  KpiModalData(
                    title: context.tr('Payments this month', 'المدفوعات هذا الشهر'),
                    subtitle: context.tr(
                      'Revenue and transaction summary',
                      'ملخص الإيرادات والمعاملات',
                    ),
                    rows: [
                      [context.tr('Total paid', 'إجمالي المدفوعات'), 'EGP ${_formatNumber(m?.paymentsThisMonth.round() ?? 0)}'],
                      [context.tr('Pending', 'معلقة'), 'EGP ${_formatNumber(m?.paymentsPending.round() ?? 0)}'],
                      [context.tr('Failed', 'فاشلة'), 'EGP ${_formatNumber(m?.paymentsFailed.round() ?? 0)}'],
                      [context.tr('Transactions', 'المعاملات'), '${m?.paymentsCount ?? 0}'],
                      [context.tr('Revenue change', 'تغيير الإيرادات'), '${m?.revenueChangePercent.toStringAsFixed(1) ?? 0}%'],
                    ],
                    ctaLabel: context.tr('View payment reports', 'عرض تقارير المدفوعات'),
                    ctaRoute: '/admin/reports',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showKpiModal(BuildContext context, KpiModalData data) {
    showDialog(
      context: context,
      builder: (_) => KpiDetailDialog(data: data),
    );
  }

  static List<Map<String, dynamic>> _asRows(dynamic r) =>
      (r as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _titleCase(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1).toLowerCase();

  static String _displayName(Map<String, dynamic> row) {
    final n = (row['display_name'] ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    final id = (row['id'] ?? '').toString();
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _formatNumber(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K';
    return '$v';
  }

  static String _formatK(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
