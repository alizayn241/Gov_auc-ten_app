import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/admin_shared.dart';

class ReportsAppBar extends SliverPersistentHeaderDelegate {
  final VoidCallback onBack;
  final VoidCallback onPickRange;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;

  const ReportsAppBar({
    required this.onBack,
    required this.onPickRange,
    required this.onRefresh,
    this.onExport,
  });

  @override
  double get minExtent => kToolbarHeight + 12;

  @override
  double get maxExtent => kToolbarHeight + 12;

  @override
  bool shouldRebuild(covariant ReportsAppBar oldDelegate) {
    return onExport != oldDelegate.onExport;
  }

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
                context.tr('Reports', 'التقارير'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              AdminTopBarButton(
                icon: Icons.date_range_rounded,
                onTap: onPickRange,
              ),
              const SizedBox(width: 6),
              AdminTopBarButton(
                icon: Icons.refresh_rounded,
                onTap: onRefresh,
              ),
              const SizedBox(width: 6),
              if (onExport != null)
                AdminTopBarButton(
                  icon: Icons.picture_as_pdf_rounded,
                  onTap: onExport,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
