import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import 'tenders_admin_models.dart';

class AdminTendersToolbarCard extends StatelessWidget {
  final TextEditingController searchController;
  final String statusFilter;
  final ValueChanged<String> onStatusChanged;
  final List<String> statusOptions;

  const AdminTendersToolbarCard({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.statusOptions,
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
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr(
                  'Search by title, entity, reference, or ID',
                  'ابحث بالعنوان أو الجهة أو المرجع أو المعرّف',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                Text(
                  context.tr('Status:', 'الحالة:'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: statusOptions
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

class AdminTendersHero extends StatelessWidget {
  final int total;
  final int openCount;
  final int awardedCount;
  final VoidCallback onCreate;

  const AdminTendersHero({
    super.key,
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
            style: const TextStyle(
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
            style: const TextStyle(
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
            style: const TextStyle(
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
              _MetricPill(
                label: context.tr('Awarded', 'مرساة'),
                value: '$awardedCount',
              ),
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

class AdminTenderCard extends StatelessWidget {
  final TenderAdminItem item;
  final VoidCallback onEdit;
  final VoidCallback onParticipants;
  final VoidCallback onAward;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusSelected;

  const AdminTenderCard({
    super.key,
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
                    PopupMenuItem(
                      value: 'evaluating',
                      child: Text('Evaluating'),
                    ),
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

class AdminTendersEmptyState extends StatelessWidget {
  const AdminTendersEmptyState({
    super.key,
    this.title = 'No tenders found',
    this.subtitle =
        'There are no tender records in the system yet, or your current filters returned no results.',
  });

  final String title;
  final String subtitle;

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
