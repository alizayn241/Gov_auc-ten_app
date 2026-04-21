import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/admin_shared.dart';

class ReportsHero extends StatelessWidget {
  final String rangeLabel;
  final VoidCallback onPickRange;
  final bool loading;

  const ReportsHero({
    super.key,
    required this.rangeLabel,
    required this.onPickRange,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 170,
            height: 170,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x1AFDC32D), Colors.transparent],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AdminTheme.heroGradient),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AdminTheme.gold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AdminTheme.gold.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: AdminTheme.gold,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: loading ? null : onPickRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AdminTheme.gold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminTheme.gold.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            size: 13,
                            color: AdminTheme.gold,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.tr('Change range', 'تغيير النطاق'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                  children: [
                    TextSpan(text: context.tr('Reporting ', 'التقارير ')),
                    TextSpan(
                      text: context.tr('overview', 'والإحصاءات'),
                      style: const TextStyle(color: AdminTheme.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Track auction operations, payment performance, and bidding momentum.',
                  'تابع عمليات المزادات وأداء المدفوعات وزخم العطاءات.',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rangeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
