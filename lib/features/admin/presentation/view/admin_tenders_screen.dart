import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tenders/data/sources/tenders_admin_remote_data_source.dart';

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
  List<_TenderAdminItem> items = const [];
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
            .map((e) => _TenderAdminItem.fromMap(Map<String, dynamic>.from(e)))
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

  List<_TenderAdminItem> get _filteredItems {
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
    final metrics = _TenderMetrics.fromItems(items);

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
          _AdminTendersHero(
            total: items.length,
            openCount: metrics.openLike,
            awardedCount: metrics.awarded,
            onCreate: () => context.push('/admin/tenders/create'),
          ),
          const SizedBox(height: 14),
          _ToolbarCard(
            searchController: _search,
            statusFilter: _statusFilter,
            onStatusChanged: (value) => setState(() => _statusFilter = value),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (error != null)
            _AdminErrorCard(message: error!, onRetry: _load)
          else if (items.isEmpty)
            const _EmptyAdminTendersState()
          else if (filtered.isEmpty)
            const _EmptyAdminTendersState(
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
                child: _TenderAdminCard(
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

class _ToolbarCard extends StatelessWidget {
  final TextEditingController searchController;
  final String statusFilter;
  final ValueChanged<String> onStatusChanged;

  const _ToolbarCard({
    required this.searchController,
    required this.statusFilter,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: context.tr(
                  'Search by title, entity, reference, or ID',
                  'ابحث بالعنوان أو الجهة أو المرجع أو المعرف',
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                Text(
                  context.tr('Status:', 'الحالة:'),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: _AdminTendersScreenState._statusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status == 'All'
                                  ? context.tr('All statuses', 'كل الحالات')
                                  : status,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => onStatusChanged(value ?? 'All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTendersHero extends StatelessWidget {
  final int total;
  final int openCount;
  final int awardedCount;
  final VoidCallback onCreate;

  const _AdminTendersHero({
    required this.total,
    required this.openCount,
    required this.awardedCount,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Procurement Control', 'التحكم في المشتريات'),
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Manage tenders with clearer operational actions',
              'إدارة المناقصات بإجراءات تشغيلية أوضح',
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'Review tender status, open participant workflows, and move into award decisions from one cleaner admin view.',
              'راجع حالة المناقصات وافتح مسارات المشاركين وانتقل إلى قرارات الترسية من واجهة إدارة أوضح.',
            ),
            style: TextStyle(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(label: context.tr('Total', 'الإجمالي'), value: '$total'),
              _MetricPill(label: context.tr('Active', 'نشطة'), value: '$openCount'),
              _MetricPill(label: context.tr('Awarded', 'مرساة'), value: '$awardedCount'),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B3C8C),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(context.tr('Create Tender', 'إنشاء مناقصة')),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenderAdminCard extends StatelessWidget {
  final _TenderAdminItem item;
  final VoidCallback onEdit;
  final VoidCallback onParticipants;
  final VoidCallback onAward;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusSelected;

  const _TenderAdminCard({
    required this.item,
    required this.onEdit,
    required this.onParticipants,
    required this.onAward,
    required this.onDelete,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusChip(text: item.status),
                          _InfoTag(
                            icon: Icons.tag_outlined,
                            text: item.referenceNo.isEmpty
                                ? 'No reference'
                                : item.referenceNo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  tooltip: 'Change status',
                  onSelected: onStatusSelected,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'draft', child: Text('Set Draft')),
                    PopupMenuItem(value: 'published', child: Text('Publish')),
                    PopupMenuItem(value: 'open', child: Text('Open')),
                    PopupMenuItem(value: 'evaluating', child: Text('Evaluating')),
                    PopupMenuItem(value: 'closed', child: Text('Close')),
                    PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailLine(
              icon: Icons.account_balance_outlined,
              label: 'Entity',
              value: item.entity,
            ),
            const SizedBox(height: 6),
            _DetailLine(
              icon: Icons.schedule_outlined,
              label: 'Deadline',
              value: item.deadlineLabel,
            ),
            const SizedBox(height: 6),
            _DetailLine(
              icon: Icons.fingerprint_outlined,
              label: 'Tender ID',
              value: item.id,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(context.tr('Edit', 'تعديل')),
                ),
                OutlinedButton.icon(
                  onPressed: onParticipants,
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text(context.tr('Participants', 'المشاركون')),
                ),
                FilledButton.icon(
                  onPressed: onAward,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: Text(context.tr('Award Lowest', 'ترسية الأقل سعراً')),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.tr('Delete', 'حذف')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final cs = Theme.of(context).colorScheme;
    final color = switch (lower) {
      'draft' => const Color(0xFF7A5D00),
      'published' || 'open' => const Color(0xFF0B6E4F),
      'evaluating' => const Color(0xFF0B3C8C),
      'awarded' => const Color(0xFF5B2E91),
      'closed' => cs.onSurfaceVariant,
      'cancelled' => const Color(0xFFB3261E),
      _ => Colors.deepOrange,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTag({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: cs.onSurface,
                  ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminErrorCard({
    required this.message,
    required this.onRetry,
  });

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

class _EmptyAdminTendersState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyAdminTendersState({
    this.title = 'No tenders found',
    this.subtitle =
        'There are no tender records in the system yet, or your current filters returned no results.',
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.request_quote_outlined,
                    color: primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => context.push('/admin/tenders/create'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(context.tr('Create Tender', 'إنشاء مناقصة')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TenderAdminItem {
  final String id;
  final String title;
  final String referenceNo;
  final String entity;
  final String status;
  final DateTime? submissionDeadline;
  final DateTime? createdAt;

  const _TenderAdminItem({
    required this.id,
    required this.title,
    required this.referenceNo,
    required this.entity,
    required this.status,
    required this.submissionDeadline,
    required this.createdAt,
  });

  factory _TenderAdminItem.fromMap(Map<String, dynamic> map) {
    return _TenderAdminItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      referenceNo: (map['reference_no'] ?? '').toString(),
      entity: (map['entity'] ?? 'Government').toString(),
      status: (map['status'] ?? 'draft').toString(),
      submissionDeadline: DateTime.tryParse(
        (map['submission_deadline'] ?? '').toString(),
      )?.toLocal(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())
          ?.toLocal(),
    );
  }

  String get deadlineLabel {
    final value = submissionDeadline;
    if (value == null) return '-';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}

class _TenderMetrics {
  final int openLike;
  final int awarded;

  const _TenderMetrics({
    required this.openLike,
    required this.awarded,
  });

  factory _TenderMetrics.fromItems(List<_TenderAdminItem> items) {
    var openLike = 0;
    var awarded = 0;

    for (final item in items) {
      final status = item.status.toLowerCase();
      if (status == 'published' || status == 'open' || status == 'evaluating') {
        openLike++;
      }
      if (status == 'awarded') {
        awarded++;
      }
    }

    return _TenderMetrics(
      openLike: openLike,
      awarded: awarded,
    );
  }
}
