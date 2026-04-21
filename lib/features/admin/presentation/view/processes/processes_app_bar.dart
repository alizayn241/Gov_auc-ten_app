import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/admin_shared.dart';

class ProcessesAppBar extends SliverPersistentHeaderDelegate {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const ProcessesAppBar({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  double get minExtent => kToolbarHeight + 12;

  @override
  double get maxExtent => kToolbarHeight + 12;

  @override
  bool shouldRebuild(covariant ProcessesAppBar oldDelegate) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AdminTheme.navy,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: kToolbarHeight + 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              AdminTopBarButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('Processes', 'العمليات'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              AdminTopBarButton(
                icon: Icons.refresh_rounded,
                onTap: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
