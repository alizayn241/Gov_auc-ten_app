class AdminInvoiceItem {
  final String id;
  final String auctionId;
  final String tenderId;
  final String userId;
  final num total;
  final String status;
  final DateTime? dueAt;
  final DateTime createdAt;

  AdminInvoiceItem({
    required this.id,
    required this.auctionId,
    required this.tenderId,
    required this.userId,
    required this.total,
    required this.status,
    required this.dueAt,
    required this.createdAt,
  });

  factory AdminInvoiceItem.fromJson(Map<String, dynamic> json) {
    return AdminInvoiceItem(
      id: json['id'].toString(),
      auctionId: (json['auction_id'] ?? '').toString(),
      tenderId: (json['tender_id'] ?? '').toString(),
      userId: json['user_id'].toString(),
      total: json['total'] as num,
      status: (json['status'] ?? '').toString(),
      dueAt: json['due_at'] == null
          ? null
          : DateTime.tryParse(json['due_at'].toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  bool get isTenderInvoice => tenderId.isNotEmpty;
}
