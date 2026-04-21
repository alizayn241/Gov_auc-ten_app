import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import 'dashboard_models.dart';

enum ChipType { success, danger, warning }

class ChipData {
  final String label;
  final ChipType type;

  const ChipData({
    required this.label,
    required this.type,
  });
}

class KpiModalData {
  final String title;
  final String subtitle;
  final List<List<String>> rows;
  final String ctaLabel;
  final String ctaRoute;

  const KpiModalData({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.ctaLabel,
    required this.ctaRoute,
  });
}

class AdminConsoleAppBarTitle extends StatelessWidget {
  final ColorScheme cs;

  const AdminConsoleAppBarTitle({super.key, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.space_dashboard_rounded, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('Admin Console', 'لوحة الإدارة'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                context.tr('Operations overview', 'نظرة عامة على العمليات'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String hint;
  final ChipData? chip;
  final bool highlight;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.hint,
    this.chip,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color chipBg, chipFg;
    switch (chip?.type) {
      case ChipType.success:
        chipBg = Colors.green.shade50;
        chipFg = Colors.green.shade700;
        break;
      case ChipType.danger:
        chipBg = Colors.red.shade50;
        chipFg = Colors.red.shade700;
        break;
      case ChipType.warning:
        chipBg = Colors.orange.shade50;
        chipFg = Colors.orange.shade700;
        break;
      default:
        chipBg = cs.surfaceVariant;
        chipFg = cs.onSurfaceVariant;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: highlight ? cs.primaryContainer.withOpacity(0.25) : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight ? cs.primary.withOpacity(0.25) : cs.outlineVariant.withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const Spacer(),
                  if (chip != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chip!.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: chipFg,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.5),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const SegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '7d', label: Text('7D')),
        ButtonSegment(value: '30d', label: Text('30D')),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class RevenueTrendCard extends StatelessWidget {
  final List<ChartPoint>? data;
  final String range;

  const RevenueTrendCard({
    super.key,
    required this.data,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = data ?? [];
    final maxY = items.isEmpty
        ? 1.0
        : items.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Revenue trend', 'اتجاه الإيراد'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            range == '7d'
                ? context.tr('Last 7 days', 'آخر 7 أيام')
                : context.tr('Last 30 days', 'آخر 30 يوما'),
            style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    horizontalInterval: maxY / 4,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: cs.outlineVariant.withOpacity(0.25),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < items.length; i++)
                          FlSpot(i.toDouble(), items[i].value),
                      ],
                      isCurved: true,
                      color: cs.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: cs.primary.withOpacity(0.12),
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

class AuctionStatusDonut extends StatelessWidget {
  final Map<String, int>? counts;

  const AuctionStatusDonut({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = counts ?? {};
    final total = items.values.fold<int>(0, (a, b) => a + b);
    final palette = [
      cs.primary,
      Colors.green,
      Colors.orange,
      Colors.red,
      cs.secondary,
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Auction status', 'حالة المزادات'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            context.tr('Distribution by current state', 'التوزيع حسب الحالة الحالية'),
            style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 42,
                  sectionsSpace: 2,
                  sections: items.entries.toList().asMap().entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.value.toDouble(),
                      color: palette[entry.key % palette.length],
                      showTitle: false,
                      radius: 18,
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UserGrowthCard extends StatelessWidget {
  final List<ChartPoint>? data;
  final double? changePercent;

  const UserGrowthCard({
    super.key,
    required this.data,
    required this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = data ?? [];
    final maxY = items.isEmpty
        ? 1.0
        : items.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('User growth', 'نمو المستخدمين'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (changePercent != null)
                Text(
                  '${changePercent! >= 0 ? '+' : ''}${changePercent!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: changePercent! >= 0 ? Colors.green : Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: cs.outlineVariant.withOpacity(0.25),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < items.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: items[i].value,
                            color: cs.primary,
                            width: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
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

class TopCategoriesCard extends StatelessWidget {
  final Map<String, int>? data;

  const TopCategoriesCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = (data ?? {}).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Top categories', 'الفئات الأعلى'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            ...items.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class TopAuctionsCard extends StatelessWidget {
  final List<TopAuction>? auctions;
  final void Function(String id) onTap;

  const TopAuctionsCard({
    super.key,
    required this.auctions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = auctions ?? [];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Highest value auctions',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            'By highest bid received',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            ...items.asMap().entries.map((e) => _AuctionRow(
                  rank: e.key + 1,
                  title: e.value.title,
                  value: 'EGP ${_formatVal(e.value.value)}',
                  isLast: e.key == items.length - 1,
                  onTap: () => onTap(e.value.id),
                )),
        ],
      ),
    );
  }
}

class ActivityFeedCard extends StatefulWidget {
  final List<ActivityItem>? items;
  final bool loading;
  final VoidCallback onViewAll;

  const ActivityFeedCard({
    super.key,
    required this.items,
    required this.loading,
    required this.onViewAll,
  });

  @override
  State<ActivityFeedCard> createState() => _ActivityFeedCardState();
}

class _ActivityFeedCardState extends State<ActivityFeedCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = widget.items ?? [];
    final visible = _expanded ? items : items.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent activity',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: widget.onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('All ->', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Text(
            'Latest platform events',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 10),
          if (widget.loading && items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No recent activity.',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.45)),
              ),
            )
          else ...[
            ...visible.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == visible.length - 1;
              return Column(
                children: [
                  _ActivityRow(item: item),
                  if (!isLast)
                    Divider(height: 14, color: cs.outlineVariant.withOpacity(0.4)),
                ],
              );
            }),
            if (items.length > 4) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'Show ${items.length - 4} more',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth >= 700 ? 5 : (c.maxWidth >= 480 ? 4 : 3);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
          children: [
            _ActionTile(icon: Icons.add_business_rounded, label: 'New auction', route: '/admin/auctions/create', navContext: ctx),
            _ActionTile(icon: Icons.playlist_add_rounded, label: 'New tender', route: '/admin/tenders/create', navContext: ctx),
            _ActionTile(icon: Icons.group_rounded, label: 'Users', route: '/admin/users', navContext: ctx),
            _ActionTile(icon: Icons.admin_panel_settings_rounded, label: 'Roles', route: '/admin/roles', navContext: ctx),
            _ActionTile(icon: Icons.rule_folder_rounded, label: 'Processes', route: '/admin/processes', navContext: ctx),
            _ActionTile(icon: Icons.description_rounded, label: 'Contracts', route: '/admin/contracts', navContext: ctx),
            _ActionTile(icon: Icons.notifications_active_rounded, label: 'Notifications', route: '/admin/notifications', navContext: ctx),
            _ActionTile(icon: Icons.security_rounded, label: 'Audit logs', route: '/admin/audit-logs', navContext: ctx),
            _ActionTile(icon: Icons.settings_rounded, label: 'Settings', route: '/admin/settings', navContext: ctx),
            _ActionTile(icon: Icons.payments_rounded, label: 'Payments', route: '/admin/reports', navContext: ctx),
          ],
        );
      },
    );
  }
}

class KpiDetailDialog extends StatelessWidget {
  final KpiModalData data;

  const KpiDetailDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(data.subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55))),
            const SizedBox(height: 16),
            ...data.rows.asMap().entries.map((e) => Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.value[0], style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6))),
                        Text(e.value[1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (e.key < data.rows.length - 1)
                    Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
                ])),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(data.ctaRoute);
                    },
                    child: Text(data.ctaLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardErrorCard extends StatelessWidget {
  final String error;

  const DashboardErrorCard({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionRow extends StatelessWidget {
  final int rank;
  final String title;
  final String value;
  final bool isLast;
  final VoidCallback onTap;

  const _AuctionRow({
    required this.rank,
    required this.title,
    required this.value,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color rankBg;
    Color rankFg;
    switch (rank) {
      case 1:
        rankBg = const Color(0xFFEF9F27);
        rankFg = const Color(0xFF412402);
        break;
      case 2:
        rankBg = const Color(0xFFB4B2A9);
        rankFg = const Color(0xFF2C2C2A);
        break;
      case 3:
        rankBg = const Color(0xFFD3D1C7);
        rankFg = const Color(0xFF2C2C2A);
        break;
      default:
        rankBg = cs.surfaceVariant;
        rankFg = cs.onSurfaceVariant;
    }
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$rank', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: rankFg)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: cs.onSurface.withOpacity(0.35)),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color dotColor;
    switch (item.type) {
      case ActivityType.user:
        dotColor = Colors.green;
        break;
      case ActivityType.approval:
        dotColor = Colors.orange;
        break;
      case ActivityType.payment:
        dotColor = cs.primary;
        break;
      case ActivityType.cancellation:
        dotColor = Colors.red;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(_relativeTime(item.sortAt), style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.4))),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final BuildContext navContext;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.navContext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => navContext.push(route),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.5),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String relativeTime(DateTime when) => _relativeTime(when);

String _relativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays}d';
}

String formatDashboardK(double v) => _formatVal(v);

String _formatVal(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}
