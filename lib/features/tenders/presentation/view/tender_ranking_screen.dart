import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/tender_ranking_row.dart';
import '../viewmodel/tenders_view_model.dart';

class TenderRankingScreen extends ConsumerStatefulWidget {
  final String tenderId;
  const TenderRankingScreen({super.key, required this.tenderId});

  @override
  ConsumerState<TenderRankingScreen> createState() => _TenderRankingScreenState();
}

class _TenderRankingScreenState extends ConsumerState<TenderRankingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(tendersViewModelProvider.notifier).loadRanking(widget.tenderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(tendersViewModelProvider);
    final lowest = st.ranking.isEmpty ? null : st.ranking.first;
    final vendorNamesFuture = _loadVendorNames(st.ranking);

    return Scaffold(
      appBar: AppBar(
        leading: AppPageBackButton(
          fallbackRoute: '/tender/${widget.tenderId}',
        ),
        title: Text(context.tr('Tender Ranking', 'ترتيب المناقصة')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(tendersViewModelProvider.notifier)
                .loadRanking(widget.tenderId),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RankingHero(
            tenderId: widget.tenderId,
            total: st.ranking.length,
            lowestLabel: lowest == null
                ? '-'
                : '${lowest.financialTotal} EGP',
          ),
          const SizedBox(height: 14),
          if (st.rankingLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (st.rankingError != null)
            _RankingStateCard(
              icon: Icons.error_outline,
              title: context.tr('Could not load ranking', 'تعذر تحميل الترتيب'),
              subtitle: st.rankingError!,
              accent: Colors.red,
            )
          else if (st.ranking.isEmpty)
            _RankingStateCard(
              icon: Icons.inbox_outlined,
              title: context.tr('No proposals yet', 'لا توجد عروض بعد'),
              subtitle: context.tr(
                'Ranking will appear here after vendors submit their lowest price offers.',
                'سيظهر الترتيب هنا بعد أن يقدّم الموردون أقل عروضهم السعرية.',
              ),
            )
          else ...[
            FutureBuilder<Map<String, String>>(
              future: vendorNamesFuture,
              builder: (context, snapshot) {
                final names = snapshot.data ?? const <String, String>{};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        context.tr('Lowest to Highest', 'من الأقل إلى الأعلى'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ...st.ranking.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RankingCard(
                          row: row,
                          displayName: names[row.vendorId] ?? _shortId(row.vendorId),
                          highlight: row.rank == 1,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, String>> _loadVendorNames(List<TenderRankingRow> ranking) async {
    final ids = ranking.map((row) => row.vendorId).toSet().toList();
    if (ids.isEmpty) return const {};

    final res = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .inFilter('id', ids);

    final map = <String, String>{};
    for (final row in (res as List)) {
      final item = Map<String, dynamic>.from(row as Map);
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;
      map[id] = _resolveDisplayName(item);
    }
    return map;
  }

  String _resolveDisplayName(Map<String, dynamic> map) {
    for (final value in [
      map['display_name'],
      map['name'],
      map['full_name'],
      map['username'],
      map['email'],
      map['id'],
    ]) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return 'User';
  }

  static String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}

class _RankingHero extends StatelessWidget {
  final String tenderId;
  final int total;
  final String lowestLabel;

  const _RankingHero({
    required this.tenderId,
    required this.total,
    required this.lowestLabel,
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
            context.tr('Proposal Comparison', 'مقارنة العروض'),
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Review the current tender ranking more clearly',
              'راجع ترتيب المناقصة الحالي بشكل أوضح',
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
            context.tr('Tender ID: $tenderId', 'رقم المناقصة: $tenderId'),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(label: context.tr('Proposals', 'العروض'), value: '$total'),
              _HeroMetric(label: context.tr('Lowest Offer', 'أقل عرض'), value: lowestLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
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

class _RankingCard extends StatelessWidget {
  final TenderRankingRow row;
  final String displayName;
  final bool highlight;

  const _RankingCard({
    required this.row,
    required this.displayName,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        highlight ? const Color(0xFF0B6E4F) : const Color(0xFF0B3C8C);
    final badgeBackground =
        highlight ? const Color(0xFFF0F7ED) : const Color(0xFFF2F6FC);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '#${row.rank}',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (highlight) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B6E4F).withOpacity(.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            context.tr('Lowest', 'الأقل'),
                            style: const TextStyle(
                              color: Color(0xFF0B6E4F),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${row.financialTotal} ${context.l10n.t('EGP', 'ج.م')}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: badgeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DetailLine(
                    icon: Icons.receipt_long_outlined,
                    label: context.tr('Proposal ID', 'رقم العرض'),
                    value: row.proposalId,
                  ),
                  const SizedBox(height: 6),
                  _DetailLine(
                    icon: Icons.schedule_outlined,
                    label: context.tr('Submitted', 'تم التقديم'),
                    value: row.submittedAt.toLocal().toString(),
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

class _RankingStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _RankingStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = const Color(0xFF0B3C8C),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 36),
            const SizedBox(height: 10),
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
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
