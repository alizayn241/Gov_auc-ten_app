import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/widgets/app_image.dart';

import '../../data/models/auction.dart';
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
                  auctionMap: {},
                  resolveTitle: (auctionId) =>
                      context.tr('Auction #$auctionId', 'مزاد رقم $auctionId'),
                ),
                data: (auctionMap) => _BidsList(
                  bids: bids,
                  auctionMap: auctionMap,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3C8C).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Bid activity', 'نشاط المزايدات'),
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Track your offers more clearly', 'تابع عروضك بشكل أوضح'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Review your submitted bids in a cleaner mobile timeline and jump back into auction details faster.',
                    'راجع مزايداتك في تسلسل أوضح على الهاتف وارجع إلى تفاصيل المزاد بسرعة أكبر.',
                  ),
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
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
  final bool? isWinner;
  final String imagePath;
  final VoidCallback onTap;

  const _BidCard({
    required this.title,
    required this.amount,
    required this.timestamp,
    this.isWinner,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    // Determine status
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isWinner == true) {
      statusText = 'Winning';
      statusColor = Colors.green;
      statusIcon = Icons.emoji_events;
    } else if (isWinner == false) {
      statusText = 'Outbid';
      statusColor = Colors.orange;
      statusIcon = Icons.trending_down;
    } else {
      statusText = 'Active';
      statusColor = cs.primary;
      statusIcon = Icons.access_time;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: AppImage(
                    imagePath: imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(
                          text: statusText,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.t('EGP', 'ج.م')} ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
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

class _BidsList extends StatelessWidget {
  final List<Bid> bids;
  final Map<String, Auction> auctionMap;
  final String Function(String auctionId) resolveTitle;

  const _BidsList({
    required this.bids,
    required this.auctionMap,
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
          final auction = auctionMap[bid.auctionId];
          final imagePath = auction?.images.isNotEmpty == true
              ? auction!.images.first
              : 'assets/images/auctions/auction_blue_01.jpg';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BidCard(
              title: resolveTitle(bid.auctionId),
              amount: bid.amount,
              timestamp: bid.timestamp,
              isWinner: bid.isWinner,
              imagePath: imagePath,
              onTap: () => context.push('/auction/${bid.auctionId}'),
            ),
          );
        }),
      ],
    );
  }
}
