import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/profile_shared.dart';

class ProfileHero extends StatelessWidget {
  final bool isAuthenticated;
  final String roleLabel;
  final IconData roleIcon;
  final bool isPhone;
  final String subtitle;

  const ProfileHero({
    super.key,
    required this.isAuthenticated,
    required this.roleLabel,
    required this.roleIcon,
    required this.isPhone,
    required this.subtitle,
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
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x20FDC32D), Colors.transparent],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: ProfileTheme.heroGradient),
          padding: EdgeInsets.fromLTRB(20, isPhone ? 20 : 26, 20, isPhone ? 24 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ProfileTheme.gold.withOpacity(0.28),
                          ProfileTheme.gold.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ProfileTheme.gold.withOpacity(0.45),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: ProfileTheme.gold,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated
                              ? context.tr('My account', 'حسابي')
                              : context.tr('Welcome', 'أهلا بك'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isPhone ? 20 : 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _RolePill(icon: roleIcon, label: roleLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RolePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ProfileTheme.gold.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: ProfileTheme.gold.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ProfileTheme.gold),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ProfileTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}
