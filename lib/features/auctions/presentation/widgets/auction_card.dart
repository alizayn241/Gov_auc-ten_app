import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/widgets/app_image.dart';

class AuctionCard extends StatelessWidget {
  final String title;
  final String location;
  final String department;
  final double currentBid;
  final double startPrice;
  final DateTime endTime;
  final String imagePath;
  final String category;
  final bool watchlisted;
  final VoidCallback onTap;
  final VoidCallback onToggleWatch;

  const AuctionCard({
    super.key,
    required this.title,
    required this.location,
    required this.department,
    required this.currentBid,
    required this.startPrice,
    required this.endTime,
    required this.imagePath,
    required this.category,
    required this.watchlisted,
    required this.onTap,
    required this.onToggleWatch,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = endTime.difference(DateTime.now());
    final endsText = remaining.isNegative
        ? 'Ended'
        : 'Ends in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AppImage(
                  imagePath: imagePath,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 92,
                    height: 92,
                    alignment: Alignment.center,
                    color: cs.surfaceContainerHighest,
                    child: const Icon(Icons.image_not_supported),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$location • $department',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(text: category),
                        _Pill(text: endsText),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Start: EGP ${startPrice.toStringAsFixed(0)}',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Text(
                          'EGP ${currentBid.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onToggleWatch,
                icon: Icon(watchlisted ? Icons.bookmark : Icons.bookmark_border),
                tooltip: watchlisted ? 'Remove from watchlist' : 'Add to watchlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
