import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'recent_activity/recent_activity_models.dart';
import 'recent_activity/recent_activity_widgets.dart';
import 'shared/admin_shared.dart';

class AdminRecentActivityScreen extends StatefulWidget {
  const AdminRecentActivityScreen({super.key});

  @override
  State<AdminRecentActivityScreen> createState() =>
      _AdminRecentActivityScreenState();
}

class _AdminRecentActivityScreenState extends State<AdminRecentActivityScreen> {
  bool _loading = true;
  String? _error;
  List<RecentActivityItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;
      final results = await Future.wait([
        sb.from('profiles').select('id,display_name,created_at'),
        sb.from('auction_participants')
            .select('user_id,status,created_at,auction_id'),
        sb.from('tender_participants')
            .select('vendor_id,status,created_at,tender_id'),
        sb.from('payments').select('id,amount,status,created_at'),
      ]);

      final profiles = asRows(results[0]);
      final auctionParticipants = asRows(results[1]);
      final tenderParticipants = asRows(results[2]);
      final payments = asRows(results[3]);

      final items = <RecentActivityItem>[
        ...profiles
            .where((row) => parseActivityDate(row['created_at']) != null)
            .map(
              (row) => RecentActivityItem(
                sortAt: parseActivityDate(row['created_at'])!,
                title: 'New user registered',
                subtitle: '${displayActivityName(row)} joined the platform',
                type: RecentActivityType.user,
              ),
            ),
        ...auctionParticipants
            .where((row) => parseActivityDate(row['created_at']) != null)
            .map((row) {
          final status = (row['status'] ?? 'pending').toString().toLowerCase();
          return RecentActivityItem(
            sortAt: parseActivityDate(row['created_at'])!,
            title: '${titleCaseActivity(status)} auction approval',
            subtitle: 'Auction ${row['auction_id']} · User ${row['user_id']}',
            type: status == 'cancelled'
                ? RecentActivityType.cancellation
                : RecentActivityType.approval,
          );
        }),
        ...tenderParticipants
            .where((row) => parseActivityDate(row['created_at']) != null)
            .map(
              (row) => RecentActivityItem(
                sortAt: parseActivityDate(row['created_at'])!,
                title:
                    '${titleCaseActivity((row['status'] ?? 'pending').toString())} tender approval',
                subtitle:
                    'Tender ${row['tender_id']} · Vendor ${row['vendor_id']}',
                type: RecentActivityType.approval,
              ),
            ),
        ...payments
            .where((row) => parseActivityDate(row['created_at']) != null)
            .map(
              (row) => RecentActivityItem(
                sortAt: parseActivityDate(row['created_at'])!,
                title: 'Payment recorded',
                subtitle:
                    'Payment ${row['id']} · EGP ${toActivityDouble(row['amount']).toStringAsFixed(0)}',
                type: RecentActivityType.payment,
              ),
            ),
      ]..sort((a, b) => b.sortAt.compareTo(a.sortAt));

      if (!mounted) return;
      setState(() {
        _items = items;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Recent Activity', 'النشاط الأخير')),
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AdminErrorCard(message: _error!, onRetry: _load),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AdminEmptyCard(
                          icon: Icons.history_toggle_off,
                          title: context.tr(
                            'No recent activity yet.',
                            'لا يوجد نشاط حديث حتى الآن.',
                          ),
                          subtitle: context.tr(
                            'New registrations, approvals, and payments will appear here once activity starts flowing through the system.',
                            'ستظهر هنا التسجيلات الجديدة والموافقات والمدفوعات عند بدء تدفق النشاط داخل النظام.',
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return RecentActivityCard(item: _items[index]);
                      },
                    ),
    );
  }
}
