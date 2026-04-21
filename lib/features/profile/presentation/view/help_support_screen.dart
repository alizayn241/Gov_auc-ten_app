import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/constants/app_constants.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'help_support/help_support_content.dart';
import 'help_support/help_support_hero.dart';
import 'shared/profile_shared.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _heroAnim;
  late final Animation<double> _bodyAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _bodyAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'Could not open this action on your device.',
            'تعذر فتح هذا الإجراء على جهازك.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ProfileTopBarDelegate(
              title: context.tr('Help & Support', 'المساعدة والدعم'),
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _heroAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.14),
                  end: Offset.zero,
                ).animate(_heroAnim),
                child: HelpSupportHero(
                  onCall: () => _launch(
                    Uri(scheme: 'tel', path: AppConstants.supportPhone),
                  ),
                  onEmail: () => _launch(
                    Uri(
                      scheme: 'mailto',
                      path: AppConstants.supportEmail,
                      query:
                          'subject=${Uri.encodeQueryComponent(AppConstants.supportEmailSubject)}',
                    ),
                  ),
                  onWhatsApp: () => _launch(
                    Uri.parse(
                      'https://wa.me/${AppConstants.supportWhatsapp.replaceAll('+', '')}?text=${Uri.encodeComponent(AppConstants.supportWhatsappMessage)}',
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _bodyAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    ProfileSectionLabel(
                      label: context.tr('Common topics', 'الموضوعات الشائعة'),
                    ),
                    const SizedBox(height: 10),
                    HelpTopicCard(
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFF15803D),
                      iconBg: const Color(0xFFE8F5E9),
                      title: context.tr('Account activation', 'تفعيل الحساب'),
                      body: context.tr(
                        'New accounts may remain pending until profile verification is completed and approved by the platform.',
                        'قد تبقى الحسابات الجديدة قيد الانتظار حتى يكتمل التحقق من الملف الشخصي وتتم الموافقة عليه.',
                      ),
                    ),
                    HelpTopicCard(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFFB45309),
                      iconBg: const Color(0xFFFFF8E1),
                      title: context.tr('Notifications', 'الإشعارات'),
                      body: context.tr(
                        'Open the notifications screen from your profile page to review the latest alerts and updates.',
                        'افتح شاشة الإشعارات من صفحة ملفك الشخصي لمراجعة أحدث التنبيهات والتحديثات.',
                      ),
                    ),
                    HelpTopicCard(
                      icon: Icons.gavel_rounded,
                      iconColor: ProfileTheme.blue,
                      iconBg: const Color(0xFFE3F0FC),
                      title: context.tr('Bids and tenders', 'المزايدات والمناقصات'),
                      body: context.tr(
                        'Use the home and auctions areas to discover items, place bids, and follow payment steps.',
                        'استخدم الصفحة الرئيسية وقسم المزادات لاكتشاف العناصر وتقديم المزايدات ومتابعة خطوات الدفع.',
                      ),
                    ),
                    HelpTopicCard(
                      icon: Icons.payments_rounded,
                      iconColor: const Color(0xFF7B1FA2),
                      iconBg: const Color(0xFFF3E5F5),
                      title: context.tr('Payments', 'المدفوعات'),
                      body: context.tr(
                        'View all your payment history and receipts from the Payments section in your profile.',
                        'يمكنك مراجعة سجل مدفوعاتك وإيصالاتك من قسم المدفوعات في ملفك الشخصي.',
                      ),
                      isLast: true,
                    ),
                    const SizedBox(height: 20),
                    ProfileSectionLabel(
                      label: context.tr('Quick access', 'وصول سريع'),
                    ),
                    const SizedBox(height: 10),
                    const HelpQuickAccessRow(),
                    const SizedBox(height: 20),
                    ProfileSectionLabel(
                      label: context.tr('How we help you', 'كيف نساعدك'),
                    ),
                    const SizedBox(height: 10),
                    const HelpSupportProcess(),
                    const SizedBox(height: 20),
                    ProfileInfoBanner(
                      text: context.tr(
                        'Forsa is a secure government auction platform. All bids are verified and legally binding under Egyptian law.',
                        'فرصة منصة حكومية آمنة. جميع العروض موثقة وملزمة قانونا بموجب القانون المصري.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
