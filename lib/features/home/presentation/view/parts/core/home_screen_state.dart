part of '../../home_screen.dart';

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _topSearch = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _heroAnim;
  late final Animation<double> _categoryAnim;
  late final Animation<double> _featuredAnim;
  late final Animation<double> _tenderAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _heroAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _categoryAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    _featuredAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.45, 0.78, curve: Curves.easeOut),
    );
    _tenderAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auctionsViewModelProvider.notifier).refresh();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _topSearch.dispose();
    super.dispose();
  }

  void _goToAuctions(String category) => context.go('/auctions?category=$category');

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

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16, 12, 16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Search auctions', 'البحث في المزادات'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topSearch,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.tr(
                    'Keyword, location, category…',
                    'كلمة مفتاحية، موقع، فئة…',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                onSubmitted: (_) {
                  Navigator.pop(context);
                  _submitSearch();
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _submitSearch();
                  },
                  icon: const Icon(Icons.search_rounded),
                  label: Text(context.tr('Search', 'بحث')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auctionsState = ref.watch(auctionsViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final notificationCount = unreadNotifications.valueOrNull ?? 0;

    final items = auctionsState.items;
    const featuredTitles = [
      'Modern Wooden Dining Table Set',
      'MacBook Pro M2 2023',
      'iPhone 14 Pro Max 256GB',
    ];

    final featured = items
        .where((a) => featuredTitles.contains(a.title))
        .toList()
      ..sort((a, b) =>
          featuredTitles.indexOf(a.title).compareTo(featuredTitles.indexOf(b.title)));

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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(auctionsViewModelProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // ── Pinned app bar ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeSliverAppBar(
                isPhone: isPhone,
                notificationCount: notificationCount,
                isAuthenticated: auth.isAuthenticated,
                searchController: _topSearch,
                onSearchTap: _openSearchSheet,
                onSearchSubmit: _submitSearch,
                onNotificationTap: () async {
                  if (!auth.isAuthenticated) {
                    context.go('/login');
                    return;
                  }
                  await context.push('/notifications');
                  ref.invalidate(unreadNotificationsCountProvider);
                },
                onTendersTap: () => context.go('/tenders'),
                onSignInTap: () => context.go('/login'),
              ),
            ),

            // ── Hero banner ──
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _heroAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(_heroAnim),
                  child: _HomeHeroSection(
                    isPhone: isPhone,
                    auctionCount: items.length,
                    featuredCount: featured.length,
                    notificationCount: notificationCount,
                    onSearchTap: isPhone ? _openSearchSheet : _submitSearch,
                    onTendersTap: () => context.go('/tenders'),
                  ),
                ),
              ),
            ),

            // ── Inline search bar (phone only, below hero) ──
            if (isPhone)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _categoryAnim,
                  child: _InlineSearchBar(
                    onTap: _openSearchSheet,
                  ),
                ),
              ),

            // ── Category row ──
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _categoryAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(_categoryAnim),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: _HomeCategoryGrid(onTap: _goToAuctions),
                  ),
                ),
              ),
            ),

            // ── Featured section header ──
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _featuredAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Featured assets', 'الأصول المميزة'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            context.tr(
                              'High-value items ending soon',
                              'عناصر مرتفعة القيمة تنتهي قريباً',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/auctions?category=All'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('View all', 'عرض الكل'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Featured auction cards (horizontal scroll) ──
            SliverToBoxAdapter(
              child: _buildFeaturedList(
                context,
                auctionsState: auctionsState,
                featured: featured,
                isTablet: isTablet,
              ),
            ),

            // ── Tenders inline banner ──
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _tenderAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(_tenderAnim),
                  child: _HomeTendersBanner(
                    onTap: () => context.go('/tenders'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedList(
    BuildContext context, {
    required dynamic auctionsState,
    required List<Auction> featured,
    required bool isTablet,
  }) {
    if (auctionsState.loading && featured.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (auctionsState.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
              const SizedBox(height: 10),
              Text(
                auctionsState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => ref.read(auctionsViewModelProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('Retry', 'إعادة المحاولة')),
              ),
            ],
          ),
        ),
      );
    }

    if (featured.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            context.tr('No auctions available yet.', 'لا توجد مزادات متاحة بعد.'),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: isTablet ? 310 : 278,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, index) {
          final auction = featured[index];
          return AnimatedBuilder(
            animation: _featuredAnim,
            builder: (ctx, child) => Opacity(
              opacity: _featuredAnim.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - _featuredAnim.value)),
                child: child,
              ),
            ),
            child: SizedBox(
              width: isTablet ? 300 : 220,
              child: _FeaturedAuctionCard(
                auction: auction,
                onTap: () => context.go('/auction/${auction.id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent app bar delegate
// ─────────────────────────────────────────────────────────────────────────────
