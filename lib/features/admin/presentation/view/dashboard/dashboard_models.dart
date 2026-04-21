class DashboardMetrics {
  final int activeProcesses;
  final int activeAuctions;
  final int activeTenders;
  final int newUsersLast30Days;
  final int newUsersLastPeriod;
  final int pendingApprovals;
  final int pendingAuctionApprovals;
  final int pendingTenderApprovals;
  final int overdueApprovals;
  final double paymentsThisMonth;
  final double paymentsPending;
  final double paymentsFailed;
  final int paymentsCount;
  final double revenueChangePercent;
  final double usersChangePercent;
  final List<ChartPoint> revenueLast7Days;
  final List<ChartPoint> revenueLast30Days;
  final List<ChartPoint> newUsersLast7Days;
  final List<ChartPoint> newUsersLast30DaysTrend;
  final Map<String, int> auctionStatusCounts;
  final Map<String, int> topCategories;
  final List<TopAuction> topAuctions;
  final List<ActivityItem> recentActivity;

  const DashboardMetrics({
    required this.activeProcesses,
    required this.activeAuctions,
    required this.activeTenders,
    required this.newUsersLast30Days,
    required this.newUsersLastPeriod,
    required this.pendingApprovals,
    required this.pendingAuctionApprovals,
    required this.pendingTenderApprovals,
    required this.overdueApprovals,
    required this.paymentsThisMonth,
    required this.paymentsPending,
    required this.paymentsFailed,
    required this.paymentsCount,
    required this.revenueChangePercent,
    required this.usersChangePercent,
    required this.revenueLast7Days,
    required this.revenueLast30Days,
    required this.newUsersLast7Days,
    required this.newUsersLast30DaysTrend,
    required this.auctionStatusCounts,
    required this.topCategories,
    required this.topAuctions,
    required this.recentActivity,
  });
}

class ChartPoint {
  final DateTime date;
  final double value;

  const ChartPoint(this.date, this.value);
}

class TopAuction {
  final String id;
  final String title;
  final double value;

  const TopAuction({
    required this.id,
    required this.title,
    required this.value,
  });
}

class ActivityItem {
  final DateTime sortAt;
  final String title;
  final String subtitle;
  final ActivityType type;

  const ActivityItem({
    required this.sortAt,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

enum ActivityType { user, approval, payment, cancellation }
