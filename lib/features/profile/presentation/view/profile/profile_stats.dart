import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/profile_shared.dart';

class ProfileStatStrip extends StatelessWidget {
  const ProfileStatStrip({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = [
      _StatData('4', 'Active bids', 'مزايداتي النشطة'),
      _StatData('12', 'Auctions', 'المزادات'),
      _StatData('2', 'Payments', 'المدفوعات'),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: ProfileTheme.heroGradient),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 8),
              child: _StatBox(data: entry.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatData {
  final String value;
  final String label;
  final String labelAr;

  const _StatData(this.value, this.label, this.labelAr);
}

class _StatBox extends StatelessWidget {
  final _StatData data;

  const _StatBox({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(data.label, data.labelAr),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
