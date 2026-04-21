part of '../../home_screen.dart';

class _HeroLiveBadge extends StatelessWidget {
  final String label;

  const _HeroLiveBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _HomeScreenTokens.liveGreen.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _HomeScreenTokens.liveGreenBg.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LivePulseDot(),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _HomeScreenTokens.liveGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
