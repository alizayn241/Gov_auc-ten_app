part of '../../home_screen.dart';

class _HomeSliverAppBar extends SliverPersistentHeaderDelegate {
  final bool isPhone;
  final int notificationCount;
  final bool isAuthenticated;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;
  final void Function(String) onSearchSubmit;
  final VoidCallback onNotificationTap;
  final VoidCallback onTendersTap;
  final VoidCallback onSignInTap;

  const _HomeSliverAppBar({
    required this.isPhone,
    required this.notificationCount,
    required this.isAuthenticated,
    required this.searchController,
    required this.onSearchTap,
    required this.onSearchSubmit,
    required this.onNotificationTap,
    required this.onTendersTap,
    required this.onSignInTap,
  });

  @override
  double get minExtent => kToolbarHeight + 12;

  @override
  double get maxExtent => kToolbarHeight + 12;

  @override
  bool shouldRebuild(covariant _HomeSliverAppBar oldDelegate) =>
      notificationCount != oldDelegate.notificationCount ||
      isAuthenticated != oldDelegate.isAuthenticated;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _HomeScreenTokens.navy,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: kToolbarHeight + 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              // Brand
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _HomeScreenTokens.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, size: 17, color: _HomeScreenTokens.gold),
              ),
              const SizedBox(width: 9),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(text: 'For'),
                    TextSpan(
                      text: 'sa',
                      style: TextStyle(color: _HomeScreenTokens.gold),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Tablet: inline search field
              if (!isPhone)
                SizedBox(
                  width: 190,
                  child: _HomeCompactSearchField(
                    controller: searchController,
                    onSubmitted: onSearchSubmit,
                  ),
                ),
              if (!isPhone) const SizedBox(width: 6),

              // Phone: search icon
              if (isPhone)
                _HomeAppBarIconButton(
                  icon: Icons.search_rounded,
                  onTap: onSearchTap,
                ),

              _HomeAppBarIconButton(
                icon: Icons.request_quote_outlined,
                onTap: onTendersTap,
              ),
              _NotificationButton(
                count: notificationCount,
                onTap: onNotificationTap,
              ),

              if (!isAuthenticated) ...[
                const SizedBox(width: 6),
                _SignInButton(onTap: onSignInTap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
