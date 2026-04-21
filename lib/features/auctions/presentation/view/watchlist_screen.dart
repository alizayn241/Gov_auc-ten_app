import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/widgets/app_image.dart';

import '../viewmodel/auctions_providers.dart';
import '../viewmodel/auctions_view_model.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(auctionsViewModelProvider.notifier);
    final watchlistAsync = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Watchlist', 'قائمة المتابعة')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            onPressed: () => ref.invalidate(watchlistProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _WatchlistHero(),
          const SizedBox(height: 16),
          watchlistAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _StateCard(
                  title: context.tr(
                    'Could not load watchlist',
                    'تعذر تحميل قائمة المتابعة',
                  ),
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                  icon: Icons.error_outline,
                  iconColor: Colors.red,
                  action: FilledButton(
                    onPressed: () => ref.invalidate(watchlistProvider),
                    child: Text(context.tr('Retry', 'إعادة المحاولة')),
                  ),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _StateCard(
                    title: context.tr(
                      'No items in watchlist',
                      'لا توجد عناصر في قائمة المتابعة',
                    ),
                    subtitle: context.tr(
                      'Save auctions here to revisit them faster from your phone.',
                      'احفظ المزادات هنا للعودة إليها سريعاً من هاتفك.',
                    ),
                    icon: Icons.favorite_border,
                  ),
                );
              }

              return Column(
                children: items
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WatchlistCard(
                          title: a.title,
                          location: a.location,
                          amount: a.currentBid,
                          imagePath: a.images.isNotEmpty
                              ? a.images.first
                              : 'assets/images/auctions/auction_blue_01.jpg',
                          status: a.status,
                          endTime: a.endTime,
                          onOpen: () => context.push('/auction/${a.id}'),
                          onRemove: () async {
                            await vm.toggleWatch(a.id);
                            ref.invalidate(watchlistProvider);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr(
                                    'Removed from watchlist',
                                    'تمت الإزالة من قائمة المتابعة',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WatchlistHero extends StatelessWidget {
  const _WatchlistHero();

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
              Icons.bookmark_border,
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
                  context.tr('Saved for later', 'محفوظة لوقت لاحق'),
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Your favorite auctions, organized', 'مزاداتك المفضلة منظمة'),
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
                    'Keep the auctions you care about in one place with a cleaner mobile browsing experience.',
                    'احتفظ بالمزادات التي تهمك في مكان واحد مع تجربة تصفح أوضح على الهاتف.',
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

class _WatchlistCard extends StatelessWidget {
  final String title;
  final String location;
  final double amount;
  final String imagePath;
  final String status;
  final DateTime endTime;
  final VoidCallback onOpen;
  final Future<void> Function() onRemove;

  const _WatchlistCard({
    required this.title,
    required this.location,
    required this.amount,
    required this.imagePath,
    required this.status,
    required this.endTime,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = endTime.difference(DateTime.now());
    final isEnded = remaining.isNegative;
    final statusText = isEnded ? 'Ended' : 'Active';
    final statusColor = isEnded ? Colors.red : Colors.green;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onOpen,
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
                  width: 100,
                  height: 100,
                  child: AppImage(
                    imagePath: imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 24),
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
                    _MetaPill(
                      icon: Icons.location_on_outlined,
                      text: location,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(
                          text: statusText,
                          color: statusColor,
                        ),
                        if (!isEnded) ...[
                          const SizedBox(width: 8),
                          _TimePill(
                            remaining: remaining,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.t('EGP', 'ج.م')} ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF0B3C8C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: context.tr('Remove', 'إزالة'),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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

class _TimePill extends StatelessWidget {
  final Duration remaining;

  const _TimePill({
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final timeText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3C8C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF0B3C8C).withOpacity(0.3)),
      ),
      child: Text(
        timeText,
        style: const TextStyle(
          color: Color(0xFF0B3C8C),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? action;

  const _StateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final resolvedIconColor = iconColor ?? primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: resolvedIconColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: resolvedIconColor, size: 30),
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
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
