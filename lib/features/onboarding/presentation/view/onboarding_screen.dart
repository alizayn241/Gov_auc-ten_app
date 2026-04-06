import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/entry_flow_tokens.dart';
import '../../../auth/presentation/viewmodel/auth_view_model.dart';
import '../widgets/entry_background.dart';
import '../widgets/onboarding_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete({required bool signup}) async {
    await ref.read(authViewModelProvider.notifier).completeOnboarding();
    if (!mounted) return;
    // context.go(signup ? '/signup' : '/login');
  }

  void _nextPage() {
    if (_pageIndex >= 2) {
      _complete(signup: true);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  List<_OnboardingItem> _items(BuildContext context) {
    return [
      _OnboardingItem(
        light: false,
        eyebrow: context.tr('INTRODUCTION', 'مقدمة'),
        title: context.tr(
          'Welcome to Forsa: The Future of Transparent Tendering.',
          'مرحبا بك في فرصة: مستقبل المناقصات الشفافة.',
        ),
        description: context.tr(
          'Access a world of professional tender opportunities with a streamlined, trustworthy mobile experience.',
          'اكتشف فرص المناقصات الاحترافية عبر تجربة هاتف موثوقة وسلسة.',
        ),
        media: const _TenderIntroArtwork(),
      ),
      _OnboardingItem(
        light: false,
        eyebrow: context.tr('INSTITUTIONAL GRADE', 'بمعايير مؤسسية'),
        title: context.tr(
          'Secure, Compliant, and Verified.',
          'آمن ومتوافق وتم التحقق منه.',
        ),
        description: context.tr(
          'Industry-standard safeguards protect every bid, document, and approval step across the platform.',
          'وسائل حماية بمعايير احترافية تحمي كل عرض وكل مستند وكل خطوة اعتماد داخل المنصة.',
        ),
        media: const _SecurityArtwork(),
      ),
      _OnboardingItem(
        light: false,
        eyebrow: context.tr('FINAL STEP', 'الخطوة الأخيرة'),
        title: context.tr(
          'Your Next Opportunity Awaits.',
          'فرصتك القادمة تنتظرك.',
        ),
        description: context.tr(
          'Join thousands of professional bidders and secure your next big contract.',
          'انضم إلى آلاف المتنافسين المحترفين واحجز عقدك القادم.',
        ),
        media: const _DashboardArtwork(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(context);

    return PageView.builder(
      controller: _pageController,
      itemCount: items.length,
      onPageChanged: (index) => setState(() => _pageIndex = index),
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        if (index == 0) {
          return _IntroTapScreen(
            onSkip: () => _complete(signup: false),
            onTapAnywhere: _nextPage,
            pageIndex: index,
            totalPages: items.length,
          );
        }

        return OnboardingShell(
          light: item.light,
          media: item.media,
          eyebrow: item.eyebrow,
          title: item.title,
          description: item.description,
          pageIndex: index,
          totalPages: items.length,
          onBack: index == 0
              ? null
              : () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                  ),
          onSkip: () => _complete(signup: false),
          onPrimaryPressed: isLast ? () => _complete(signup: true) : _nextPage,
          primaryLabel: isLast
              ? context.tr('Create Account  ->', 'إنشاء حساب  ->')
              : context.tr('Next  ->', 'التالي  ->'),
          secondaryAction: isLast
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _complete(signup: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0x1FFFFFFF),
                      side: BorderSide(color: Colors.white.withOpacity(.12)),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(context.tr('Login', 'تسجيل الدخول')),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _OnboardingItem {
  final bool light;
  final String eyebrow;
  final String title;
  final String description;
  final Widget media;

  const _OnboardingItem({
    required this.light,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.media,
  });
}

class _IntroTapScreen extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onTapAnywhere;
  final int pageIndex;
  final int totalPages;

  const _IntroTapScreen({
    required this.onSkip,
    required this.onTapAnywhere,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTapAnywhere,
        child: EntryBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Forsa',
                        style: TextStyle(
                          color: Color(0xFF3F4F6B),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onSkip,
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            color: EntryFlowTokens.textMuted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18263F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.16),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E3A34),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFF6BF0BF),
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Forsa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      height: .95,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'TENDERING REIMAGINED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EntryFlowTokens.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 54),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: EntryFlowTokens.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.tr(
                      'INITIALIZING SECURE ENVIRONMENT',
                      'جار تهيئة البيئة الآمنة',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EntryFlowTokens.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  _IntroPagerDots(
                    currentIndex: pageIndex,
                    total: totalPages,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPagerDots extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _IntroPagerDots({
    required this.currentIndex,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final active = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active
                  ? EntryFlowTokens.accentWarm
                  : Colors.white.withOpacity(.24),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}

class _TenderIntroArtwork extends StatelessWidget {
  const _TenderIntroArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF142443),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.08), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B39B).withOpacity(.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash/picture1.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF091A36).withOpacity(.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4038),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 16,
                  color: Color(0xFF6BF0BF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityArtwork extends StatelessWidget {
  const _SecurityArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 150,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FB),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 36,
                color: EntryFlowTokens.backgroundTop,
              ),
            ),
          ),
          const Positioned(
            left: 22,
            bottom: 28,
            child: _FloatingChip(
              icon: Icons.lock_rounded,
              color: EntryFlowTokens.accent,
            ),
          ),
          const Positioned(
            right: 26,
            top: 22,
            child: _FloatingChip(
              icon: Icons.key_rounded,
              color: EntryFlowTokens.accentWarm,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardArtwork extends StatelessWidget {
  const _DashboardArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 284,
      height: 350,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF243652),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/splash/picture2.png',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF091A36).withOpacity(.10),
                          const Color(0xFF091A36).withOpacity(.56),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x99D9DFE8),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: EntryFlowTokens.accent,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'MARKET ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF435268),
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingChip({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
