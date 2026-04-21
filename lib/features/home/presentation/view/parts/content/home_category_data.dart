part of '../../home_screen.dart';

class _HomeCategoryData {
  final String label;
  final String arabicLabel;
  final IconData icon;
  final Color color;

  const _HomeCategoryData(this.label, this.arabicLabel, this.icon, this.color);

  String localizedLabel(BuildContext context) => context.tr(label, arabicLabel);
}

// ─────────────────────────────────────────────────────────────────────────────
// Upgraded auction card
// ─────────────────────────────────────────────────────────────────────────────
