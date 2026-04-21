part of '../../home_screen.dart';

class _HomeHeroSection extends StatelessWidget {
  final bool isPhone;
  final int auctionCount;
  final int featuredCount;
  final int notificationCount;
  final VoidCallback onSearchTap;
  final VoidCallback onTendersTap;

  const _HomeHeroSection({
    required this.isPhone,
    required this.auctionCount,
    required this.featuredCount,
    required this.notificationCount,
    required this.onSearchTap,
    required this.onTendersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background glow — gold top-right
        Positioned(
          top: -40,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x26FDC32D), Colors.transparent],
              ),
            ),
          ),
        ),
        // Background glow — blue bottom-left
        Positioned(
          bottom: -30,
          left: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_HomeScreenTokens.blue.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),

        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: _HomeScreenTokens.heroGradient,
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            isPhone ? 22 : 28,
            20,
            isPhone ? 28 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top badges row
              Row(
                children: [
                  _HeroTrustBadge(label: context.tr('Trusted · Government', 'موثوق · حكومي')),
                  const Spacer(),
                  _HeroLiveBadge(label: context.tr('Live now', 'مباشر الآن')),
                ],
              ),
              const SizedBox(height: 18),

              // Headline
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPhone ? 30 : 36,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.6,
                  ),
                  children: [
                    TextSpan(text: context.tr('Bid on ', 'تنافس على ')),
                    TextSpan(
                      text: context.tr('verified', 'موثقة'),
                      style: const TextStyle(color: _HomeScreenTokens.gold),
                    ),
                    TextSpan(text: context.tr('\ngovernment assets', '\nأصول حكومية')),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sub-headline
              Text(
                context.tr(
                  'High-value lots, real-time bidding, and official tenders — all in one secure platform.',
                  'قطع عالية القيمة ومزايدة في الوقت الفعلي ومناقصات رسمية — كل ذلك في منصة واحدة آمنة.',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),

              // Trust pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroFeaturePill(
                    icon: Icons.verified_rounded,
                    label: context.tr('Verified assets', 'أصول موثقة'),
                  ),
                  _HeroFeaturePill(
                    icon: Icons.lock_rounded,
                    label: context.tr('Secure payments', 'مدفوعات آمنة'),
                  ),
                  _HeroFeaturePill(
                    icon: Icons.bolt_rounded,
                    label: context.tr('Fast approvals', 'موافقات سريعة'),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _HeroMetricCard(
                      value: '$auctionCount',
                      label: context.tr('Live auctions', 'مزادات حالية'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroMetricCard(
                      value: '$featuredCount',
                      label: context.tr('Featured', 'مميزة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroMetricCard(
                      value: '$notificationCount',
                      label: context.tr('Updates', 'تحديثات'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _PrimaryActionButton(
                      icon: Icons.search_rounded,
                      label: context.tr('Search', 'بحث'),
                      onTap: onSearchTap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryActionButton(
                      icon: Icons.request_quote_outlined,
                      label: context.tr('Tenders', 'المناقصات'),
                      onTap: onTendersTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
