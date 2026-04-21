import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/admin_reports_model.dart';
import '../utils/admin_reports_pdf.dart';
import 'reports/reports_app_bar.dart';
import 'reports/reports_hero.dart';
import 'reports/reports_panels.dart';
import 'shared/admin_shared.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  bool _loading = false;
  String? _error;
  AdminReportsSummary? _data;

  late final AnimationController _animCtrl;
  late final Animation<double> _heroAnim;
  late final Animation<double> _bodyAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _heroAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _bodyAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _loadReports();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _yyyyMmDd(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final result = await client.rpc(
        'get_admin_reports_summary',
        params: {
          'from_date': _yyyyMmDd(_range.start),
          'to_date': _yyyyMmDd(_range.end),
        },
      );

      final parsed = AdminReportsSummary.fromJson(
        Map<String, dynamic>.from(result as Map),
      );

      if (!mounted) return;
      setState(() {
        _data = parsed;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
    );

    if (picked == null) return;
    setState(() => _range = picked);
    await _loadReports();
  }

  Future<void> _exportPdf() async {
    if (_data == null) return;
    final doc = await AdminReportsPdf.build(
      data: _data!,
      from: _range.start,
      to: _range.end,
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  BidsByDayPoint? get _peakBidDay {
    final data = _data;
    if (data == null || data.bidsByDay.isEmpty) return null;
    return data.bidsByDay.reduce((a, b) => a.count >= b.count ? a : b);
  }

  CategoryAmountPoint? get _topCategory {
    final data = _data;
    if (data == null || data.revenueByCategory.isEmpty) return null;
    return data.revenueByCategory.reduce((a, b) => a.amount >= b.amount ? a : b);
  }

  double get _avgBidsPerDay {
    final data = _data;
    if (data == null) return 0;
    return data.bidsCount / (_range.duration.inDays + 1);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final data = _data;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ReportsAppBar(
              onBack: () => context.canPop() ? context.pop() : context.go('/home'),
              onPickRange: _pickRange,
              onRefresh: _loadReports,
              onExport: (data == null || _loading) ? null : _exportPdf,
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _heroAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(_heroAnim),
                child: ReportsHero(
                  rangeLabel:
                      '${dateFormat.format(_range.start)} - ${dateFormat.format(_range.end)}',
                  onPickRange: _pickRange,
                  loading: _loading,
                ),
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
                    const SizedBox(height: 16),
                    InsightStrip(
                      daysInRange: _range.duration.inDays + 1,
                      peakBidDay: _peakBidDay == null
                          ? context.tr('No bid activity', 'لا يوجد نشاط')
                          : '${dateFormat.format(_peakBidDay!.date)} · ${_peakBidDay!.count}',
                      topCategory: _topCategory?.category.isNotEmpty == true
                          ? _topCategory!.category
                          : context.tr('None yet', 'لا توجد بعد'),
                      avgBidsPerDay: _avgBidsPerDay,
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                    if (_error != null) ...[
                      AdminErrorCard(message: _error!, onRetry: _loadReports),
                      const SizedBox(height: 14),
                    ],
                    if (data != null) ...[
                      AdminSectionLabel(
                        label: context.tr('Key metrics', 'المؤشرات الرئيسية'),
                      ),
                      const SizedBox(height: 10),
                      MetricGrid(data: data, avgBidsPerDay: _avgBidsPerDay),
                      const SizedBox(height: 20),
                      AdminSectionLabel(
                        label: context.tr('Bids by day', 'العطاءات حسب اليوم'),
                      ),
                      const SizedBox(height: 10),
                      BidsByDayPanel(data: data, dateFormat: dateFormat),
                      const SizedBox(height: 16),
                      AdminSectionLabel(
                        label: context.tr('Revenue by category', 'الإيراد حسب الفئة'),
                      ),
                      const SizedBox(height: 10),
                      RevenueByCategoryPanel(data: data),
                    ] else if (!_loading && _error == null) ...[
                      AdminEmptyCard(
                        icon: Icons.analytics_rounded,
                        title: context.tr(
                          'No report data yet',
                          'لا توجد بيانات تقارير بعد',
                        ),
                        subtitle: context.tr(
                          'Try another date range or refresh.',
                          'جرّب نطاقا آخر أو حدّث التقرير.',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
