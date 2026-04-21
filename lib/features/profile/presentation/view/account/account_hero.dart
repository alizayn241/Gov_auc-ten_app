import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import 'account_profile.dart';
import 'account_shared.dart';

class AccountHero extends StatelessWidget {
  final AccountProfile profile;
  final String displayName;

  const AccountHero({
    super.key,
    required this.profile,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(profile.status);
    final statusLabel = _statusLabel(context, profile.status);

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
          decoration: const BoxDecoration(gradient: AccountTheme.heroGradient),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AccountTheme.gold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AccountTheme.gold.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AccountTheme.gold,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  _StatusPill(color: statusColor, label: statusLabel),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                AccountText.orDash(displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.shield_rounded,
                    label: AccountText.labelize(profile.role),
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.badge_rounded,
                    label: AccountText.labelize(profile.accountType),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _statusNote(context, profile.status),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
        return AccountTheme.successFg;
      case 'rejected':
      case 'suspended':
        return AccountTheme.dangerFg;
      default:
        return AccountTheme.warningFg;
    }
  }

  static String _statusLabel(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
        return context.tr('Active', 'مفعل');
      case 'rejected':
        return context.tr('Rejected', 'مرفوض');
      case 'suspended':
        return context.tr('Suspended', 'موقوف');
      default:
        return context.tr('Pending review', 'قيد المراجعة');
    }
  }

  static String _statusNote(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
        return context.tr(
          'Your account is active and ready for auctions and tenders.',
          'حسابك مفعل وجاهز للمزادات والمناقصات.',
        );
      case 'rejected':
        return context.tr(
          'Verification was rejected. Contact support for next steps.',
          'تم رفض التحقق. تواصل مع الدعم للخطوات التالية.',
        );
      case 'suspended':
        return context.tr(
          'Account is temporarily suspended. Contact support.',
          'الحساب موقوف مؤقتا. تواصل مع الدعم.',
        );
      default:
        return context.tr(
          'Your account is pending verification. Once approved, it becomes fully active.',
          'حسابك بانتظار التحقق. بعد الموافقة يصبح مفعلا بالكامل.',
        );
    }
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
