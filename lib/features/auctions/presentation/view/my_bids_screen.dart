import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/bid.dart';
import '../viewmodel/auctions_providers.dart';
import '../viewmodel/auctions_view_model.dart';

class MyBidsScreen extends ConsumerWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(auctionsViewModelProvider.notifier);
    final bidsAsync = ref.watch(myBidsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('My Bids', 'مزايداتي')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            onPressed: () {
              ref.invalidate(myBidsProvider);
              vm.refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _MyBidsHero(),
          const SizedBox(height: 16),
          bidsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => _EmptyState(
              title: context.tr('Could not load your bids', 'تعذر تحميل مزايداتك'),
              subtitle: error.toString().replaceFirst('Exception: ', ''),
              icon: Icons.error_outline,
            ),
            data: (bids) {
              if (bids.isEmpty) {
                return _EmptyState(
                  title: context.tr('No bids yet', 'لا توجد مزايدات بعد'),
                  subtitle: context.tr(
                    'Place a bid on any auction and it will appear here instantly.',
                    'قدّم مزايدة على أي مزاد وستظهر هنا فوراً.',
                  ),
                  icon: Icons.receipt_long,
                );
              }

              final auctionIds = bids.map((b) => b.auctionId).toSet().toList()
                ..sort();
              final auctionsAsync = ref.watch(
                myBidAuctionsProvider(auctionIds.join('|')),
              );

              return auctionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => _BidsList(
                  bids: bids,
                  resolveTitle: (auctionId) =>
                      context.tr('Auction #$auctionId', 'مزاد رقم $auctionId'),
                ),
                data: (auctionMap) => _BidsList(
                  bids: bids,
                  resolveTitle: (auctionId) =>
                      auctionMap[auctionId]?.title ??
                      context.tr('Auction #$auctionId', 'مزاد رقم $auctionId'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MyBidsHero extends StatelessWidget {
  const _MyBidsHero();

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
            context.tr('Bid activity', 'نشاط المزايدات'),
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            context.tr('Track your offers more clearly', 'تابع عروضك بشكل أوضح'),
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
              'Review your submitted bids in a cleaner mobile timeline and jump back into auction details faster.',
              'راجع مزايداتك في تسلسل أوضح على الهاتف وارجع إلى تفاصيل المزاد بسرعة أكبر.',
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

class _BidCard extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime timestamp;
  final VoidCallback onTap;

  const _BidCard({
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.t('EGP', 'ج.م')} ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timestamp.toLocal().toString(),
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: primary, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
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
          ],
        ),
      ),
    );
  }
}

class _BidsList extends StatelessWidget {
  final List<Bid> bids;
  final String Function(String auctionId) resolveTitle;

  const _BidsList({
    required this.bids,
    required this.resolveTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            context.tr('${bids.length} bids tracked', '${bids.length} مزايدة مسجلة'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        ...bids.map((bid) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BidCard(
              title: resolveTitle(bid.auctionId),
              amount: bid.amount,
              timestamp: bid.timestamp,
              onTap: () => context.push('/auction/${bid.auctionId}'),
            ),
          );
        }),
      ],
    );
  }
}
