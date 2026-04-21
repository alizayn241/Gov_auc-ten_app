import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/features/admin/data/models/admin_reports_model.dart';
import 'package:intl/intl.dart';


class InsightStrip extends StatelessWidget {
  final int daysInRange;
  final String peakBidDay;
  final String topCategory;
  final double avgBidsPerDay;

  const InsightStrip({
    super.key,
    required this.daysInRange,
    required this.peakBidDay,
    required this.topCategory,
    required this.avgBidsPerDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InsightChip(
            icon: Icons.calendar_month_rounded,
            label: context.tr('Coverage', 'التغطية'),
            value: '$daysInRange ${context.tr('days', 'أيام')}',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _InsightChip(
            icon: Icons.local_fire_department_rounded,
            label: context.tr('Peak day', 'أعلى يوم'),
            value: peakBidDay,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _InsightChip(
            icon: Icons.speed_rounded,
            label: context.tr('Daily pace', 'الوتيرة'),
            value: avgBidsPerDay.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }
}

class MetricGrid extends StatelessWidget {
  final AdminReportsSummary data;
  final double avgBidsPerDay;

  const MetricGrid({
    super.key,
    required this.data,
    required this.avgBidsPerDay,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 130,
      ),
      children: [
        _MetricCard(
          icon: Icons.gavel_rounded,
          label: context.tr('Active auctions', 'المزادات النشطة'),
          value: '${data.activeAuctions}',
          iconColor: const Color(0xFF185FA5),
          iconBg: const Color(0xFFE6F1FB),
        ),
        _MetricCard(
          icon: Icons.trending_up_rounded,
          label: context.tr('Bids recorded', 'العروض المسجلة'),
          value: '${data.bidsCount}',
          iconColor: const Color(0xFF534AB7),
          iconBg: const Color(0xFFEEEDFE),
        ),
        _MetricCard(
          icon: Icons.payments_rounded,
          label: context.tr('Payments total', 'إجمالي المدفوعات'),
          value: 'EGP ${_formatK(data.paymentsTotal)}',
          iconColor: const Color(0xFF0F6E56),
          iconBg: const Color(0xFFE1F5EE),
        ),
        _MetricCard(
          icon: Icons.speed_rounded,
          label: context.tr('Avg bids/day', 'متوسط العروض'),
          value: avgBidsPerDay.toStringAsFixed(1),
          iconColor: const Color(0xFF854F0B),
          iconBg: const Color(0xFFFAEEDA),
        ),
      ],
    );
  }
}

class BidsByDayPanel extends StatelessWidget {
  final AdminReportsSummary data;
  final DateFormat dateFormat;

  const BidsByDayPanel({
    super.key,
    required this.data,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = data.bidsByDay.isEmpty
        ? 1
        : data.bidsByDay.map((point) => point.count).reduce(math.max);
    final cs = Theme.of(context).colorScheme;

    return _PanelCard(
      child: data.bidsByDay.isEmpty
          ? _PanelEmpty(
              message: context.tr(
                'No bids in this date range.',
                'لا توجد عطاءات في هذا النطاق.',
              ),
            )
          : Column(
              children: data.bidsByDay.take(7).map((point) {
                final fill = maxCount == 0 ? 0.0 : point.count / maxCount;
                final isPeak = point.count == maxCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFormat.format(point.date),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${point.count}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isPeak
                                  ? const Color(0xFF185FA5)
                                  : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: fill,
                          minHeight: 7,
                          backgroundColor: cs.surfaceVariant.withOpacity(0.4),
                          valueColor: AlwaysStoppedAnimation(
                            isPeak
                                ? const Color(0xFF185FA5)
                                : const Color(0xFF378ADD),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class RevenueByCategoryPanel extends StatelessWidget {
  final AdminReportsSummary data;

  const RevenueByCategoryPanel({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.revenueByCategory.isEmpty
        ? 1.0
        : data.revenueByCategory.map((point) => point.amount).reduce(math.max);
    final cs = Theme.of(context).colorScheme;

    return _PanelCard(
      child: data.revenueByCategory.isEmpty
          ? _PanelEmpty(
              message: context.tr(
                'No category revenue data.',
                'لا توجد بيانات إيرادات حسب الفئة.',
              ),
            )
          : Column(
              children: data.revenueByCategory.take(7).map((item) {
                final fill = maxAmount == 0 ? 0.0 : item.amount / maxAmount;
                final isTop = item.amount == maxAmount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.category.isEmpty
                                  ? context.tr('Uncategorized', 'غير مصنفة')
                                  : item.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'EGP ${_formatK(item.amount)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isTop
                                  ? const Color(0xFF0F6E56)
                                  : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: fill,
                          minHeight: 7,
                          backgroundColor: cs.surfaceVariant.withOpacity(0.4),
                          valueColor: AlwaysStoppedAnimation(
                            isTop
                                ? const Color(0xFF0F6E56)
                                : const Color(0xFF639922),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withOpacity(0.5),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;

  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
      ),
      child: child,
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  final String message;

  const _PanelEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}

String _formatK(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}
