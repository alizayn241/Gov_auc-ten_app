import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/admin_reports_model.dart';
import '../utils/admin_reports_pdf.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  bool _loading = false;
  String? _error;
  AdminReportsSummary? _data;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  String _yyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
 
final user = client.auth.currentUser;
debugPrint('SUPABASE USER: ${user?.id} | ${user?.email}');
if (user == null) {
  throw Exception('Not logged in to Supabase');
}
      final res = await client.rpc(
        'get_admin_reports_summary',
        params: {
          'from_date': _yyyyMmDd(_range.start),
          'to_date': _yyyyMmDd(_range.end),
        },
      );

      final map = Map<String, dynamic>.from(res as Map);
      final parsed = AdminReportsSummary.fromJson(map);

      setState(() {
        _data = parsed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
    final data = _data;
    if (data == null) return;

    final doc = await AdminReportsPdf.build(
      data: data,
      from: _range.start,
      to: _range.end,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final df = DateFormat('yyyy-MM-dd');

    // ✅ fallback values if data not loaded yet
    final auctionsValue =
        _data == null ? '—' : '${_data!.activeAuctions} Active';
    final bidsValue = _data == null ? '—' : '${_data!.bidsCount} Bids';
    final paymentsValue = _data == null
        ? '—'
        : 'EGP ${_data!.paymentsTotal.toStringAsFixed(0)}';
    final usersValue =
        '—'; // لو تحب نضيفها لاحقًا من RPC (newUsers)

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Reports', 'التقارير')),
        leading: IconButton(
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
            tooltip: context.tr('Date Range', 'النطاق الزمني'),
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
          ),
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
          IconButton(
            tooltip: context.tr('Export PDF', 'تصدير PDF'),
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: (_data == null || _loading) ? null : _exportPdf,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Date Range card
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickRange,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Date Range: ${df.format(_range.start)} → ${df.format(_range.end)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          if (_loading) const LinearProgressIndicator(),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          _ReportCard(
            icon: Icons.gavel,
            title: 'Auctions Report',
            subtitle: 'Overview of all active and closed auctions',
            value: auctionsValue,
            color: primary,
          ),
          const SizedBox(height: 12),

          _ReportCard(
            icon: Icons.history,
            title: 'Bids Report',
            subtitle: 'Total bids in selected date range',
            value: bidsValue,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 12),

          _ReportCard(
            icon: Icons.payments,
            title: 'Revenue Report',
            subtitle: 'Total payments processed (selected range)',
            value: paymentsValue,
            color: Colors.green,
          ),
          const SizedBox(height: 12),

          _ReportCard(
            icon: Icons.people,
            title: 'Users Activity',
            subtitle: 'New users and engagement metrics (optional)',
            value: usersValue,
            color: Colors.orange,
          ),

          const SizedBox(height: 14),

          if (_data != null) ...[
            const Text(
              'Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),

            // ✅ Bid history mini table preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bids By Day (preview)',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    if (_data!.bidsByDay.isEmpty)
                      Text(
                        'No bids in this range.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ..._data!.bidsByDay.take(6).map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(df.format(p.date))),
                              Text(
                                p.count.toString(),
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue By Category (preview)',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    if (_data!.revenueByCategory.isEmpty)
                      Text(
                        'No category data.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ..._data!.revenueByCategory.take(6).map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(c.category)),
                              Text(
                                'EGP ${c.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color color;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
