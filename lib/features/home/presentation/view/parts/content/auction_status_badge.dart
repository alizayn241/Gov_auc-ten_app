part of '../../home_screen.dart';

class _AuctionStatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _AuctionStatusBadge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tender inline banner
// ─────────────────────────────────────────────────────────────────────────────
