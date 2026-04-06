import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';

import '../../../auth/presentation/viewmodel/auth_view_model.dart';
import '../viewmodel/tenders_view_model.dart';

class TendersListScreen extends ConsumerStatefulWidget {
  const TendersListScreen({super.key});

  @override
  ConsumerState<TendersListScreen> createState() => _TendersListScreenState();
}

class _TendersListScreenState extends ConsumerState<TendersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tendersViewModelProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(tendersViewModelProvider);
    final auth = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppPageBackButton(fallbackRoute: '/home'),
        title: Text(context.tr('Government Tenders', 'المناقصات الحكومية')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tendersViewModelProvider.notifier).load(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _TendersHero(),
          const SizedBox(height: 16),
          if (st.loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (st.error != null)
            _TendersError(message: st.error!)
          else if (st.items.isEmpty)
            _EmptyTendersState(
              title: context.tr('No tenders available', 'لا توجد مناقصات متاحة'),
              subtitle: context.tr(
                'There are no published tenders right now. Please check again later.',
                'لا توجد مناقصات منشورة حالياً. يرجى المحاولة لاحقاً.',
              ),
              showAdminAction: auth.isAdmin,
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                context.tr(
                  '${st.items.length} active tenders',
                  '${st.items.length} مناقصة نشطة',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            ...st.items.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TenderCard(
                  title: t.title,
                  reference: t.referenceNo ?? '-',
                  entity: t.entity ?? context.tr('Government entity', 'جهة حكومية'),
                  status: t.status,
                  deadline: t.submissionDeadline,
                  onTap: () => context.go('/tender/${t.id}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TendersHero extends StatelessWidget {
  const _TendersHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Public procurement', 'المشتريات العامة'),
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            context.tr(
              'Compare tenders with a cleaner mobile layout',
              'قارن المناقصات عبر واجهة أوضح على الهاتف',
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            context.tr(
              'Review deadlines, entity information, and move into lowest-offer submission with less clutter.',
              'راجع المواعيد النهائية ومعلومات الجهة وانتقل لتقديم أقل عرض بسلاسة أكبر.',
            ),
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenderCard extends StatelessWidget {
  final String title;
  final String reference;
  final String entity;
  final String status;
  final DateTime deadline;
  final VoidCallback onTap;

  const _TenderCard({
    required this.title,
    required this.reference,
    required this.entity,
    required this.status,
    required this.deadline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(
                    label: status,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MetaLine(
                icon: Icons.tag_outlined,
                text: context.tr('Reference: $reference', 'المرجع: $reference'),
              ),
              const SizedBox(height: 6),
              _MetaLine(
                icon: Icons.account_balance_outlined,
                text: entity,
              ),
              const SizedBox(height: 6),
              _MetaLine(
                icon: Icons.schedule_outlined,
                text: context.tr(
                  'Deadline: ${deadline.toLocal()}',
                  'آخر موعد: ${deadline.toLocal()}',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    context.tr('Open details', 'فتح التفاصيل'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'awarded':
        return Colors.green;
      case 'closed':
      case 'cancelled':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return const Color(0xFF0B3C8C);
    }
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: cs.onSurface, height: 1.25),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TendersError extends StatelessWidget {
  final String message;

  const _TendersError({required this.message});

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
          ],
        ),
      ),
    );
  }
}

class _EmptyTendersState extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showAdminAction;

  const _EmptyTendersState({
    required this.title,
    required this.subtitle,
    required this.showAdminAction,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
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
                if (showAdminAction) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.push('/admin/tenders/create'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(context.tr('Create Tender', 'إنشاء مناقصة')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
