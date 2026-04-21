part of '../../home_screen.dart';

class _SignInButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: _HomeScreenTokens.gold,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            context.tr('Sign in', 'دخول'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _HomeScreenTokens.navy,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact search field (tablet appbar)
// ─────────────────────────────────────────────────────────────────────────────
