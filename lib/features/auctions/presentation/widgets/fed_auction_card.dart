import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/widgets/app_image.dart';

class FedAuctionCard extends StatelessWidget {
  final String image;
  final String title;
  final String location;
  final double currentBid;
  final String timeLeft;

  /// show Active badge (ONLY when not endingSoon)
  final bool active;

  /// show Ending Soon badge (priority)
  final bool endingSoon;

  final VoidCallback onTap;

  const FedAuctionCard({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.currentBid,
    required this.timeLeft,
    required this.active,
    required this.endingSoon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ✅ SINGLE badge (priority: Ending Soon > Active > Ended)
    final badgeText = endingSoon ? 'Ending Soon' : (active ? 'Active' : 'Ended');
    final badgeBg = endingSoon
        ? const Color(0xFFFFE8E8)
        : (active
              ? cs.primary.withOpacity(.12)
              : cs.surfaceContainerHighest.withOpacity(.9));
    final badgeFg = endingSoon
        ? const Color(0xFFB42318)
        : (active ? cs.primary : cs.onSurfaceVariant);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) {
            final isTight = c.maxHeight < 260;

            return Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Image area
                Expanded(
                  flex: isTight ? 6 : 7,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(
                        imagePath: image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surface,
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.image_not_supported, size: 42),
                        ),
                      ),

                      // badge (top-right)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _Badge(
                          text: badgeText,
                          bg: badgeBg,
                          fg: badgeFg,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Text + meta area (NO overflow)
                Expanded(
                  flex: isTight ? 5 : 6,
                  child: ClipRect(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        isTight ? 10 : 14,
                        14,
                        isTight ? 10 : 14,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // title
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // current bid
                            _Meta(
                              label: 'CURRENT BID',
                              value: 'EGP ${currentBid.toStringAsFixed(0)}',
                            ),

                            const SizedBox(height: 10),

                            // time left
                            _Meta(
                              label: 'TIME LEFT',
                              value: timeLeft,
                              valueColor:
                                  endingSoon ? const Color(0xFFB42318) : null,
                              icon: Icons.schedule,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Badge({
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const _Meta({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: .6,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: valueColor ?? cs.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: valueColor ?? cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
