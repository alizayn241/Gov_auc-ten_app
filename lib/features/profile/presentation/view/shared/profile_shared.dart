import 'package:flutter/material.dart';

class ProfileTheme {
  static const Color navy = Color(0xFF091F45);
  static const Color navyMid = Color(0xFF0D3478);
  static const Color blue = Color(0xFF1565C0);
  static const Color gold = Color(0xFFFDC32D);
  static const Color goldDark = Color(0xFFB45309);
  static const Color dangerBg = Color(0xFFFCEBEB);
  static const Color dangerFg = Color(0xFFA32D2D);
  static const Color dangerBorder = Color(0xFFE24B4A);
  static const Color liveGreen = Color(0xFF16A34A);

  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyMid, Color(0xFF1A5199)],
    stops: [0.0, 0.55, 1.0],
  );
}

class ProfileTopBarDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final VoidCallback onBack;

  const ProfileTopBarDelegate({
    required this.title,
    required this.onBack,
  });

  @override
  double get minExtent => kToolbarHeight + 12;

  @override
  double get maxExtent => kToolbarHeight + 12;

  @override
  bool shouldRebuild(covariant ProfileTopBarDelegate oldDelegate) {
    return title != oldDelegate.title || onBack != oldDelegate.onBack;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: ProfileTheme.navy,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: kToolbarHeight + 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _ProfileBackButton(onTap: onBack),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              const _ProfileBrandMark(),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSectionLabel extends StatelessWidget {
  final String label;

  const ProfileSectionLabel({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        letterSpacing: 0.85,
      ),
    );
  }
}

class ProfileInfoBanner extends StatelessWidget {
  final String text;

  const ProfileInfoBanner({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ProfileTheme.navyMid, ProfileTheme.blue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ProfileTheme.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: ProfileTheme.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ProfileBrandMark extends StatelessWidget {
  const _ProfileBrandMark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
        children: [
          TextSpan(text: 'For'),
          TextSpan(
            text: 'sa',
            style: TextStyle(color: ProfileTheme.gold),
          ),
        ],
      ),
    );
  }
}
