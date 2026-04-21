part of '../../home_screen.dart';

class _FeaturedAuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onTap;

  const _FeaturedAuctionCard({required this.auction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = auction.images.isNotEmpty
        ? auction.images.first
        : 'assets/images/auctions/auction_blue_01.jpg';
    final remaining = auction.endTime.difference(DateTime.now());
    final isActive = !remaining.isNegative;
    final isEndingSoon = isActive && remaining.inHours <= 24;

    final timeLeft = !isActive
        ? context.tr('Ended', 'منتهٍ')
        : '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 148,
                    width: double.infinity,
                    child: image.startsWith('assets/')
                        ? Image.asset(image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _AuctionCardImagePlaceholder())
                        : Image.network(image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _AuctionCardImagePlaceholder()),
                  ),
                  // Status badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: isEndingSoon
                        ? _AuctionStatusBadge(
                            label: context.tr('Ending soon', 'ينتهي قريباً'),
                            bg: const Color(0xFFFFF8E1),
                            fg: _HomeScreenTokens.goldDark,
                          )
                        : isActive
                            ? _AuctionStatusBadge(
                                label: context.tr('Live', 'مباشر'),
                                bg: const Color(0xFFE8F5E9),
                                fg: _HomeScreenTokens.liveGreen,
                              )
                            : _AuctionStatusBadge(
                                label: context.tr('Ended', 'منتهٍ'),
                                bg: Colors.grey.shade100,
                                fg: Colors.grey.shade600,
                              ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (auction.location.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12, color: cs.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            auction.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Current bid', 'العرض الحالي'),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withOpacity(0.45),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'EGP ${_fmt(auction.currentBid)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: isEndingSoon
                                ? _HomeScreenTokens.gold.withOpacity(0.12)
                                : cs.primaryContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_rounded,
                                size: 11,
                                color: isEndingSoon
                                    ? _HomeScreenTokens.goldDark
                                    : cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeLeft,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isEndingSoon ? _HomeScreenTokens.goldDark : cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
