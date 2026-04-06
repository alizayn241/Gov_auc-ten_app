import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/constants/app_constants.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:gov_auction_app/features/onboarding/presentation/widgets/entry_background.dart';

import '../viewmodel/auth_view_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authViewModelProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    final elapsed = DateTime.now().difference(_startedAt);
    final phaseLabel = state.isInitialized
        ? 'Preparing your dashboard'
        : elapsed.inMilliseconds > 1200
            ? 'Securing your workspace'
            : 'Initializing secure environment';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EntryBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: fade,
            builder: (context, _) {
              return Opacity(
                opacity: fade.value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - fade.value)),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Row(
                          children: [
                            Text(
                              'Forsa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Spacer(),
                            Text(
                              'SKIP',
                              style: TextStyle(
                                color: EntryFlowTokens.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: EntryFlowTokens.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: EntryFlowTokens.borderSoft,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.18),
                              blurRadius: 22,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: EntryFlowTokens.backgroundBottom,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: EntryFlowTokens.accent,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          height: .96,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'TENDERING REIMAGINED',
                        style: TextStyle(
                          color: EntryFlowTokens.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 56),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            EntryFlowTokens.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        phaseLabel.toUpperCase(),
                        style: const TextStyle(
                          color: EntryFlowTokens.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _SplashDot(active: true),
                          _SplashDot(),
                          _SplashDot(),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashDot extends StatelessWidget {
  final bool active;

  const _SplashDot({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 22 : 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active
            ? EntryFlowTokens.accentWarm
            : EntryFlowTokens.textPrimary.withOpacity(.24),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
