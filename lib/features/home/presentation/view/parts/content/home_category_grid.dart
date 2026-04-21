part of '../../home_screen.dart';

class _HomeCategoryGrid extends StatelessWidget {
  final void Function(String) onTap;

  const _HomeCategoryGrid({required this.onTap});

  static const _cats = <_HomeCategoryData>[
    _HomeCategoryData('Vehicles', 'المركبات', Icons.directions_car_rounded, Color(0xFF0D47A1)),
    _HomeCategoryData('Real Estate', 'العقارات', Icons.location_city_rounded, Color(0xFF2E7D32)),
    _HomeCategoryData('Electronics', 'الإلكترونيات', Icons.devices_rounded, Color(0xFF1565C0)),
    _HomeCategoryData('Industrial', 'الصناعة', Icons.factory_rounded, Color(0xFFF9A825)),
    _HomeCategoryData('Jewelry', 'المجوهرات', Icons.diamond_rounded, Color(0xFFD32F2F)),
    _HomeCategoryData('Furniture', 'الأثاث', Icons.chair_alt_rounded, Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('Browse categories', 'تصفح حسب الفئة'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            TextButton(
              onPressed: () => context.go('/auctions?category=All'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.tr('See all', 'الكل'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.25,
          children: _cats.map((cat) {
            return InkWell(
              onTap: () => onTap(cat.label),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withOpacity(0.12)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.localizedLabel(context),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withOpacity(0.85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
