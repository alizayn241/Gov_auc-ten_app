import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:go_router/go_router.dart';

import '../../../auctions/data/models/auction.dart';
import '../../../auctions/presentation/viewmodel/auctions_view_model.dart';
import '../../../auctions/presentation/widgets/fed_auction_card.dart';
import '../../../auth/presentation/viewmodel/auth_view_model.dart';
import '../../../notifications/presentation/viewmodel/notifications_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _topSearch = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auctionsViewModelProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _topSearch.dispose();
    super.dispose();
  }

  void _goToAuctions(String category) {
    context.go('/auctions?category=$category');
  }

  void _submitSearch([String? rawQuery]) {
    final query = (rawQuery ?? _topSearch.text).trim();
    final uri = Uri(
      path: '/auctions',
      queryParameters: {
        'category': 'All',
        if (query.isNotEmpty) 'search': query,
      },
    );
    context.go(uri.toString());
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('Search', 'بحث'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _topSearch,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: context.tr(
                      'Search by keyword or location...',
                      'ابحث بالكلمة المفتاحية أو الموقع...',
                    ),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) {
                    Navigator.pop(context);
                    _submitSearch();
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _submitSearch();
                    },
                    child: Text(context.tr('Search', 'بحث')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auctionsState = ref.watch(auctionsViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    final items = auctionsState.items;
    const featuredTitles = [
      'Modern Wooden Dining Table Set',
      'MacBook Pro M2 2023',
      'iPhone 14 Pro Max 256GB',
    ];

    final featured = items
        .where((auction) => featuredTitles.contains(auction.title))
        .toList()
      ..sort((a, b) {
        return featuredTitles.indexOf(a.title).compareTo(
          featuredTitles.indexOf(b.title),
        );
      });

    if (featured.isEmpty) {
      featured.addAll([...items]..sort((a, b) {
            final ra = a.endTime.difference(DateTime.now());
            final rb = b.endTime.difference(DateTime.now());
            return ra.inSeconds.compareTo(rb.inSeconds);
          }));
    }

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 650;
    final isPhone = width < 650;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: isPhone ? 34 : 36,
              height: isPhone ? 34 : 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/logos/gov_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.gavel, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Forsa'),
          ],
        ),
        actions: [
          if (isPhone)
            IconButton(
              tooltip: context.tr('Search', 'بحث'),
              icon: const Icon(Icons.search),
              onPressed: () => _openSearchSheet(context),
            )
          else
            SizedBox(
              width: 190,
              child: _TopSearchField(
                controller: _topSearch,
                onSubmitted: _submitSearch,
              ),
            ),
          IconButton(
            tooltip: context.tr('Tenders', 'المناقصات'),
            icon: const Icon(Icons.request_quote),
            onPressed: () => context.go('/tenders'),
          ),
          IconButton(
            tooltip: context.tr('Notifications', 'الإشعارات'),
            icon: _NotificationBellBadge(
              count: unreadNotifications.valueOrNull ?? 0,
            ),
            onPressed: () async {
              if (!auth.isAuthenticated) {
                context.go('/login');
                return;
              }
              await context.push('/notifications');
              ref.invalidate(unreadNotificationsCountProvider);
            },
          ),
          if (!auth.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: SizedBox(
                height: isPhone ? 40 : 38,
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: isPhone ? 14 : 16),
                  ),
                  child: Text(context.tr('Sign In', 'تسجيل الدخول')),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(auctionsViewModelProvider.notifier).refresh(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroBanner(
              isPhone: isPhone,
              onSearchTap: isPhone
                  ? () => _openSearchSheet(context)
                  : () => _submitSearch(),
              onTendersTap: () => context.go('/tenders'),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CategoryRow(onTap: _goToAuctions),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    context.tr('Featured Assets', 'الأصول المميزة'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: context.tr('Refresh auctions', 'تحديث المزادات'),
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        ref.read(auctionsViewModelProvider.notifier).refresh(),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/auctions?category=All'),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(context.tr('View All', 'عرض الكل')),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('High-value items ending soon', 'عناصر مرتفعة القيمة تنتهي قريباً'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (auctionsState.loading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 26),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (auctionsState.error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 30),
                      const SizedBox(height: 10),
                      Text(
                        auctionsState.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(auctionsViewModelProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                        label: Text(context.tr('Retry', 'إعادة المحاولة')),
                      ),
                    ],
                  ),
                ),
              )
            else if (featured.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: _EmptyAuctionsText()),
              )
            else
              SizedBox(
                height: isTablet ? 360 : 330,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final auction = featured[index];
                    return SizedBox(
                      width: isTablet ? 340 : 286,
                      child: _FeaturedAuctionCard(
                        auction: auction,
                        onTap: () => context.go('/auction/${auction.id}'),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _NotificationBellBadge extends StatelessWidget {
  final int count;

  const _NotificationBellBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeCount = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none_outlined),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD62828),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                badgeCount,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedAuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onTap;

  const _FeaturedAuctionCard({
    required this.auction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = auction.images.isNotEmpty
        ? auction.images.first
        : 'assets/images/auctions/auction_blue_01.jpg';
    final remaining = auction.endTime.difference(DateTime.now());
    final isActive = !remaining.isNegative;
    final isEndingSoon = isActive && remaining.inHours <= 24;
    final showActive = !isEndingSoon && isActive;

    final timeLeft = !isActive
        ? context.tr('Ended', 'منتهٍ')
        : context.tr(
            '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left',
            'متبقي ${remaining.inHours}س ${remaining.inMinutes.remainder(60)}د',
          );

    return FedAuctionCard(
      image: image,
      title: auction.title,
      location: auction.location,
      currentBid: auction.currentBid,
      timeLeft: timeLeft,
      active: showActive,
      endingSoon: isEndingSoon,
      onTap: onTap,
    );
  }
}

class _TopSearchField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmitted;

  const _TopSearchField({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: context.tr('Search auctions...', 'ابحث في المزادات...'),
          prefixIcon: Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isPhone;
  final VoidCallback onSearchTap;
  final VoidCallback onTendersTap;

  const _HeroBanner({
    required this.isPhone,
    required this.onSearchTap,
    required this.onTendersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.all(isPhone ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EntryFlowTokens.backgroundTop, EntryFlowTokens.backgroundBottom],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'Find trusted public auctions and tenders',
              'اعثر على المزادات والمناقصات الحكومية الموثوقة',
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: isPhone ? 28 : 34,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'Browse newly added opportunities, compare assets, and track government tenders from one place.',
              'تصفح الفرص المضافة حديثاً وقارن الأصول وتابع المناقصات الحكومية من مكان واحد.',
            ),
            style: TextStyle(
              color: Colors.white.withOpacity(.86),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSearchTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: EntryFlowTokens.backgroundTop,
                  ),
                  icon: const Icon(Icons.search),
                  label: Text(context.tr('Search', 'بحث')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTendersTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(.45)),
                  ),
                  icon: const Icon(Icons.request_quote),
                  label: Text(context.tr('Tenders', 'المناقصات')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final void Function(String) onTap;

  const _CategoryRow({required this.onTap});

  static const _categories = <String>[
    'Vehicles',
    'Real Estate',
    'Electronics',
    'Industrial',
    'Jewelry',
    'Furniture',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.light
        ? Colors.black87
        : Colors.white;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories
          .map(
            (category) => ActionChip(
              label: Text(
                category,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              avatar: Icon(Icons.arrow_outward, size: 16, color: textColor),
              onPressed: () => onTap(category),
            ),
          )
          .toList(),
    );
  }
}

class _EmptyAuctionsText extends StatelessWidget {
  const _EmptyAuctionsText();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      context.tr('No auctions available yet.', 'لا توجد مزادات متاحة بعد.'),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
