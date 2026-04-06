class TenderParticipation {
  final String vendorId;
  final String status;
  final bool eligible;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const TenderParticipation({
    required this.vendorId,
    required this.status,
    required this.eligible,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory TenderParticipation.fromJson(Map<String, dynamic> json) {
    return TenderParticipation(
      vendorId: (json['vendor_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      eligible: (json['eligible'] ?? false) == true,
      reviewedAt: DateTime.tryParse((json['reviewed_at'] ?? '').toString())
          ?.toLocal(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString())
          ?.toLocal(),
    );
  }
}
