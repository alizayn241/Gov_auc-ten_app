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
            context.tr('Saved for later', 'محفوظة لوقت لاحق'),
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            context.tr('Your favorite auctions, organized', 'مزاداتك المفضلة منظمة'),
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
              'Keep the auctions you care about in one place with a cleaner mobile browsing experience.',
              'احتفظ بالمزادات التي تهمك في مكان واحد مع تجربة تصفح أوضح على الهاتف.',
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

class _WatchlistCard extends StatelessWidget {
  final String title;
  final String location;
  final double amount;
  final String imagePath;
  final VoidCallback onOpen;
  final Future<void> Function() onRemove;

  const _WatchlistCard({
    required this.title,
    required this.location,
    required this.amount,
    required this.imagePath,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onOpen,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 90,
                  height: 90,
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
                    _MetaPill(
                      icon: Icons.location_on_outlined,
                      text: location,
                    ),
                    const SizedBox(height: 8),
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
              const SizedBox(width: 10),
              IconButton(
                tooltip: context.tr('Remove', 'إزالة'),
                icon: const Icon(Icons.favorite, color: Colors.red),
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
