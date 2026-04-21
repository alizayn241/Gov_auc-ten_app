import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tenders/data/sources/tenders_admin_remote_data_source.dart';
import 'shared/admin_shared.dart';
import 'tenders_admin/tenders_admin_models.dart';
import 'tenders_admin/tenders_admin_widgets.dart';

class AdminTendersScreen extends StatefulWidget {
  const AdminTendersScreen({super.key});

  @override
  State<AdminTendersScreen> createState() => _AdminTendersScreenState();
}

class _AdminTendersScreenState extends State<AdminTendersScreen> {
  bool loading = true;
  String? error;
  String _statusFilter = 'All';
  final _search = TextEditingController();
  List<TenderAdminItem> items = const [];
  final _remote = TendersAdminRemoteDataSource(Supabase.instance.client);

  static const _statusOptions = [
    'All',
    'draft',
    'published',
    'open',
    'evaluating',
    'awarded',
    'closed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final rows = await Supabase.instance.client
          .from('tenders')
          .select(
            'id,title,reference_no,entity,status,submission_deadline,created_at',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        items = (rows as List)
            .map((e) => TenderAdminItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _changeStatus({
    required String tenderId,
    required String status,
  }) async {
    try {
      await _remote.updateTenderStatus(tenderId: tenderId, status: status);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.toLowerCase() == 'closed'
                ? context.tr(
                    'Tender closed and submission deadline finalized.',
                    'تم إغلاق المناقصة وتثبيت موعد انتهاء التقديم.',
                  )
                : context.tr(
                    'Tender status updated to $status',
                    'تم تحديث حالة المناقصة إلى $status',
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _deleteTender(String tenderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Delete Tender', 'حذف المناقصة')),
        content: Text(
          context.tr(
            'This will permanently delete the tender record. Do you want to continue?',
            'سيؤدي هذا إلى حذف سجل المناقصة نهائياً. هل تريد المتابعة؟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            child: Text(context.tr('Delete', 'حذف')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _remote.deleteTender(tenderId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Tender deleted', 'تم حذف المناقصة'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  List<TenderAdminItem> get _filteredItems {
    final query = _search.text.trim().toLowerCase();

    return items.where((item) {
      if (_statusFilter != 'All' && item.status != _statusFilter) return false;
      if (query.isEmpty) return true;

      return item.title.toLowerCase().contains(query) ||
          item.entity.toLowerCase().contains(query) ||
          item.referenceNo.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final metrics = TenderMetrics.fromItems(items);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Tender Management', 'إدارة المناقصات')),
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
        actions: [
          IconButton(
            tooltip: context.tr('Create tender', 'إنشاء مناقصة'),
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/tenders/create'),
          ),
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
          AdminTendersHero(
            total: items.length,
            openCount: metrics.openLike,
            awardedCount: metrics.awarded,
            onCreate: () => context.push('/admin/tenders/create'),
          ),
          const SizedBox(height: 14),
          AdminTendersToolbarCard(
            searchController: _search,
            statusFilter: _statusFilter,
            statusOptions: _statusOptions,
            onStatusChanged: (value) => setState(() => _statusFilter = value),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (error != null)
            AdminErrorCard(message: error!, onRetry: _load)
          else if (items.isEmpty)
            const AdminTendersEmptyState()
          else if (filtered.isEmpty)
            const AdminTendersEmptyState(
              title: 'No tenders match these filters',
              subtitle:
                  'Try adjusting the status filter or search phrase to see more records.',
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${filtered.length} tenders shown',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            ...filtered.map(
              (tender) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminTenderCard(
                  item: tender,
                  onEdit: () => context.push('/admin/tenders/${tender.id}/edit'),
                  onParticipants: () => context.push(
                    '/admin/tenders/${tender.id}/participants',
                  ),
                  onAward: () => context.push('/admin/tenders/${tender.id}/award'),
                  onDelete: () => _deleteTender(tender.id),
                  onStatusSelected: (status) => _changeStatus(
                    tenderId: tender.id,
                    status: status,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/admin/tenders/create'),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(context.tr('New Tender', 'مناقصة جديدة')),
            ),
    );
  }
}
