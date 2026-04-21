import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/profile_shared.dart';

class HelpTopicCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final bool isLast;

  const HelpTopicCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  State<HelpTopicCard> createState() => _HelpTopicCardState();
}

class _HelpTopicCardState extends State<HelpTopicCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 8),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _expanded
                  ? widget.iconColor.withOpacity(0.35)
                  : cs.outline.withOpacity(0.14),
              width: _expanded ? 1 : 0.5,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 48),
                  child: Text(
                    widget.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.65),
                      height: 1.5,
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpQuickAccessRow extends StatelessWidget {
  const HelpQuickAccessRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      _QuickItem(Icons.person_rounded, context.tr('Account', 'الحساب'), ProfileTheme.blue),
      _QuickItem(Icons.notifications_rounded, context.tr('Alerts', 'التنبيهات'), const Color(0xFFB45309)),
      _QuickItem(Icons.payments_rounded, context.tr('Payments', 'المدفوعات'), const Color(0xFF7B1FA2)),
    ];

    return Row(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class HelpSupportProcess extends StatelessWidget {
  const HelpSupportProcess({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = [
      _StepData(
        icon: Icons.person_search_rounded,
        title: context.tr('Review your account status', 'راجع حالة حسابك'),
        body: context.tr(
          'Start with the account page to confirm activation and profile data.',
          'ابدأ من صفحة الحساب لتأكيد حالة التفعيل وبيانات الملف الشخصي.',
        ),
      ),
      _StepData(
        icon: Icons.notifications_active_rounded,
        title: context.tr('Check your notifications', 'تحقق من إشعاراتك'),
        body: context.tr(
          'Important alerts and platform updates may already contain the answer.',
          'قد تحتوي التنبيهات المهمة وتحديثات المنصة بالفعل على الإجابة.',
        ),
      ),
      _StepData(
        icon: Icons.support_agent_rounded,
        title: context.tr('Reach support if needed', 'تواصل مع الدعم عند الحاجة'),
        body: context.tr(
          'If the issue remains unresolved, use call, email, or WhatsApp above.',
          'إذا استمرت المشكلة، استخدم الاتصال أو البريد الإلكتروني أو واتساب أعلاه.',
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final isLast = entry.key == steps.length - 1;
          final step = entry.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ProfileTheme.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(step.icon, color: ProfileTheme.blue, size: 18),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: ProfileTheme.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.body,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.55),
                          height: 1.45,
                        ),
                      ),
                      if (!isLast) const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickItem(this.icon, this.label, this.color);
}

class _StepData {
  final IconData icon;
  final String title;
  final String body;

  const _StepData({
    required this.icon,
    required this.title,
    required this.body,
  });
}
