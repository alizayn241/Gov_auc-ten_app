class ContractRow {
  final String id;
  final String tenderId;
  final String vendorId;
  final String status;
  final String contractValue;
  final DateTime? createdAt;

  const ContractRow({
    required this.id,
    required this.tenderId,
    required this.vendorId,
    required this.status,
    required this.contractValue,
    required this.createdAt,
  });

  factory ContractRow.fromMap(Map<String, dynamic> map) {
    return ContractRow(
      id: (map['id'] ?? '').toString(),
      tenderId: (map['tender_id'] ?? '').toString(),
      vendorId: (map['vendor_id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      contractValue: (map['contract_value'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())
          ?.toLocal(),
    );
  }

  String get createdAtLabel {
    final value = createdAt;
    if (value == null) return '-';
    return value.toString();
  }
}
