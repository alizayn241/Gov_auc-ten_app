class TenderParticipantMini {
  final String vendorId;
  final String status;
  final bool eligible;

  const TenderParticipantMini({
    required this.vendorId,
    required this.status,
    required this.eligible,
  });

  factory TenderParticipantMini.fromMap(Map<String, dynamic> map) {
    return TenderParticipantMini(
      vendorId: (map['vendor_id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      eligible: (map['eligible'] ?? false) == true,
    );
  }
}
