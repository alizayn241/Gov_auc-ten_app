part of '../../home_screen.dart';

class _InlineSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _InlineSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        height: 46,
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, size: 18, color: cs.onSurface.withOpacity(0.4)),
            const SizedBox(width: 10),
            Text(
              context.tr('Search by keyword or location…', 'ابحث بالكلمة المفتاحية أو الموقع…'),
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category grid
// ─────────────────────────────────────────────────────────────────────────────
