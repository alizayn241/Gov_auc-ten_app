class TenderParticipantItem {
  final String vendorId;
  final String status;
  final bool eligible;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const TenderParticipantItem({
    required this.vendorId,
    required this.status,
    required this.eligible,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory TenderParticipantItem.fromMap(Map<String, dynamic> map) {
    return TenderParticipantItem(
      vendorId: (map['vendor_id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      eligible: (map['eligible'] ?? false) == true,
      reviewedAt: DateTime.tryParse(
        (map['reviewed_at'] ?? '').toString(),
      )?.toLocal(),
      createdAt: DateTime.tryParse(
        (map['created_at'] ?? '').toString(),
      )?.toLocal(),
    );
  }

  String get reviewedAtLabel => _format(reviewedAt);
  String get createdAtLabel => _format(createdAt);

  static String _format(DateTime? value) {
    if (value == null) return '-';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}
