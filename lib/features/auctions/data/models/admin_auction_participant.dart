class AdminAuctionParticipant {
  final String userId;
  final String status;
  final bool eligible;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  AdminAuctionParticipant({
    required this.userId,
    required this.status,
    required this.eligible,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory AdminAuctionParticipant.fromJson(Map<String, dynamic> json) {
    return AdminAuctionParticipant(
      userId: json['user_id'].toString(),
      status: (json['status'] ?? '').toString(),
      eligible: (json['eligible'] ?? false) == true,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.tryParse(json['reviewed_at'].toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}