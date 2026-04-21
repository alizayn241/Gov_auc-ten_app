import 'package:flutter/material.dart';

import 'recent_activity_models.dart';

class RecentActivityCard extends StatelessWidget {
  final RecentActivityItem item;

  const RecentActivityCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      RecentActivityType.user => const Color(0xFF1565C0),
      RecentActivityType.approval => const Color(0xFF0B6E4F),
      RecentActivityType.payment => const Color(0xFF9C6B00),
      RecentActivityType.cancellation => const Color(0xFFB3261E),
    };

    final icon = switch (item.type) {
      RecentActivityType.user => Icons.person_add_alt_1_rounded,
      RecentActivityType.approval => Icons.verified_user_rounded,
      RecentActivityType.payment => Icons.payments_rounded,
      RecentActivityType.cancellation => Icons.cancel_outlined,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatActivityDate(item.sortAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
