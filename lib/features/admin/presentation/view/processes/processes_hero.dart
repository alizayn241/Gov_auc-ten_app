import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/admin_shared.dart';

class ProcessesHero extends StatelessWidget {
  final int auctionCount;
  final int tenderCount;
  final int pendingCount;

  const ProcessesHero({
    super.key,
    required this.auctionCount,
    required this.tenderCount,
    required this.pendingCount,
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
            width: 160,
            height: 160,
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
                  Icons.rule_folder_rounded,
                  color: AdminTheme.gold,
                  size: 22,
                ),
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
                    TextSpan(text: context.tr('Active ', 'العمليات ')),
                    TextSpan(
                      text: context.tr('processes', 'النشطة'),
                      style: const TextStyle(color: AdminTheme.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Manage auctions and tenders through their full lifecycle.',
                  'أدر المزادات والمناقصات عبر دورة حياتها الكاملة.',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      value: '$auctionCount',
                      label: context.tr('Auctions', 'المزادات'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroStat(
                      value: '$tenderCount',
                      label: context.tr('Tenders', 'المناقصات'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroStat(
                      value: '$pendingCount',
                      label: context.tr('Pending', 'معلقة'),
                      warn: pendingCount > 0,
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

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final bool warn;

  const _HeroStat({
    required this.value,
    required this.label,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: warn ? AdminTheme.gold.withOpacity(0.15) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: warn
              ? AdminTheme.gold.withOpacity(0.4)
              : Colors.white.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: warn ? AdminTheme.gold : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: (warn ? AdminTheme.gold : Colors.white).withOpacity(0.65),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
