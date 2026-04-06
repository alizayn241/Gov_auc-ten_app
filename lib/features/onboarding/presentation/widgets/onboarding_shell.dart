import 'package:flutter/material.dart';

import '../../../../core/theme/entry_flow_tokens.dart';
import 'entry_background.dart';

class OnboardingShell extends StatelessWidget {
  final Widget media;
  final String eyebrow;
  final String title;
  final String description;
  final int pageIndex;
  final int totalPages;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final VoidCallback onPrimaryPressed;
  final String primaryLabel;
  final bool light;
  final Widget? secondaryAction;

  const OnboardingShell({
    super.key,
    required this.media,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.pageIndex,
    required this.totalPages,
    required this.onSkip,
    required this.onPrimaryPressed,
    required this.primaryLabel,
    this.onBack,
    this.light = false,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final titleColor = light ? EntryFlowTokens.textDark : EntryFlowTokens.textPrimary;
    final bodyColor = light ? EntryFlowTokens.textDarkMuted : EntryFlowTokens.textMuted;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EntryBackground(
        light: light,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        _TopActionButton(
                          icon: onBack == null ? Icons.close : Icons.arrow_back,
                          onTap: onBack,
                          visible: onBack != null,
                          dark: !light,
                        ),
                        if (onBack != null) const SizedBox(width: 2),
                        Text(
                          'Forsa',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          color: bodyColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        media,
                        const SizedBox(height: 30),
                        Text(
                          eyebrow,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: EntryFlowTokens.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: isPhone ? 32 : 36,
                            fontWeight: FontWeight.w900,
                            height: 1.04,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: bodyColor,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _PagerDots(
                  currentIndex: pageIndex,
                  total: totalPages,
                  activeColor: EntryFlowTokens.accentWarm,
                  inactiveColor: light ? EntryFlowTokens.lightBorder : EntryFlowTokens.textPrimary.withOpacity(.25),
                ),
                const SizedBox(height: EntryFlowTokens.spaceLg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onPrimaryPressed,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: EntryFlowTokens.accent,
                            foregroundColor: EntryFlowTokens.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            primaryLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (secondaryAction != null) ...[
                        const SizedBox(height: EntryFlowTokens.spaceSm),
                        secondaryAction!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool visible;
  final bool dark;

  const _TopActionButton({
    required this.icon,
    required this.onTap,
    required this.visible,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox(width: 48, height: 48);
    }

    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: dark ? EntryFlowTokens.borderSoft : EntryFlowTokens.lightSurface,
        foregroundColor: dark ? EntryFlowTokens.textPrimary : EntryFlowTokens.textDark,
      ),
      icon: Icon(icon),
    );
  }
}

class _PagerDots extends StatelessWidget {
  final int currentIndex;
  final int total;
  final Color activeColor;
  final Color inactiveColor;

  const _PagerDots({
    required this.currentIndex,
    required this.total,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
