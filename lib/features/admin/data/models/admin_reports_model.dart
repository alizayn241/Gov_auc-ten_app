class AdminReportsSummary {
  final int activeAuctions;
  final int bidsCount;
  final double paymentsTotal;

  final List<BidsByDayPoint> bidsByDay;
  final List<CategoryAmountPoint> revenueByCategory;

  AdminReportsSummary({
    required this.activeAuctions,
    required this.bidsCount,
    required this.paymentsTotal,
    required this.bidsByDay,
    required this.revenueByCategory,
  });

  factory AdminReportsSummary.fromJson(Map<String, dynamic> json) {
    return AdminReportsSummary(
      activeAuctions: (json['activeAuctions'] as num?)?.toInt() ?? 0,
      bidsCount: (json['bidsCount'] as num?)?.toInt() ?? 0,
      paymentsTotal: (json['paymentsTotal'] as num?)?.toDouble() ?? 0.0,
      bidsByDay: (json['bidsByDay'] as List<dynamic>? ?? const [])
          .map((e) => BidsByDayPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      revenueByCategory:
          (json['revenueByCategory'] as List<dynamic>? ?? const [])
              .map((e) => CategoryAmountPoint.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class BidsByDayPoint {
  final DateTime date;
  final int count;

  BidsByDayPoint({required this.date, required this.count});

  factory BidsByDayPoint.fromJson(Map<String, dynamic> json) {
    return BidsByDayPoint(
      date: DateTime.parse(json['date'] as String),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryAmountPoint {
  final String category;
  final double amount;

  CategoryAmountPoint({required this.category, required this.amount});

  factory CategoryAmountPoint.fromJson(Map<String, dynamic> json) {
    return CategoryAmountPoint(
      category: (json['category'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}