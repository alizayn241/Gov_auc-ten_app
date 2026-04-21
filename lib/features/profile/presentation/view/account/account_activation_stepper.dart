import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import 'account_profile.dart';
import 'account_shared.dart';

class AccountActivationStepper extends StatelessWidget {
  final AccountProfile profile;

  const AccountActivationStepper({
    super.key,
    required this.profile,
  });

  bool get _isActive {
    final status = profile.status.toLowerCase();
    return status == 'active' || status == 'approved' || status == 'verified';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = AccountTheme.successFg;
    final pendingColor = AccountTheme.warningFg;
    final step2Color = _isActive ? activeColor : pendingColor;
    final step3Color = _isActive ? activeColor : cs.onSurface.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StepRow(
            icon: Icons.check_circle_rounded,
            iconColor: activeColor,
            title: context.tr('Account created', 'تم إنشاء الحساب'),
            subtitle: context.tr(
              'Profile registered in the system.',
              'تم تسجيل ملفك في النظام.',
            ),
            lineColor: activeColor,
            showLine: true,
          ),
          _StepRow(
            icon: Icons.manage_search_rounded,
            iconColor: step2Color,
            title: context.tr('Verification review', 'مراجعة التحقق'),
            subtitle: _reviewSubtitle(context, profile.status),
            lineColor: step2Color,
            showLine: true,
          ),
          _StepRow(
            icon: Icons.verified_user_rounded,
            iconColor: step3Color,
            title: context.tr('Full access', 'الوصول الكامل'),
            subtitle: _isActive
                ? context.tr(
                    'Your account is ready for full platform participation.',
                    'حسابك جاهز للمشاركة الكاملة في المنصة.',
                  )
                : context.tr(
                    'Full access will be enabled after verification.',
                    'سيتم تفعيل الوصول الكامل بعد التحقق.',
                  ),
          ),
        ],
      ),
    );
  }

  static String _reviewSubtitle(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
        return context.tr('Account is active and verified.', 'الحساب مفعل وموثق.');
      case 'rejected':
        return context.tr(
          'Verification rejected. Contact support.',
          'تم رفض التحقق. تواصل مع الدعم.',
        );
      case 'suspended':
        return context.tr(
          'Account suspended. Contact support.',
          'الحساب موقوف. تواصل مع الدعم.',
        );
      default:
        return context.tr(
          'Awaiting review and approval.',
          'بانتظار المراجعة والموافقة.',
        );
    }
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? lineColor;
  final bool showLine;

  const _StepRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.lineColor,
    this.showLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: (lineColor ?? cs.outline).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.55),
                    height: 1.4,
                  ),
                ),
                if (showLine) const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
