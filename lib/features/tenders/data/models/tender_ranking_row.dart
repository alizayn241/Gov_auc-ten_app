class TenderRankingRow {
  final String proposalId;
  final String vendorId;
  final num financialTotal;
  final String currency;
  final DateTime submittedAt;
  final int rank;

  TenderRankingRow({
    required this.proposalId,
    required this.vendorId,
    required this.financialTotal,
    required this.currency,
    required this.submittedAt,
    required this.rank,
  });

  static dynamic _pick(Map<String, dynamic> json, String a, String b) {
    if (json.containsKey(a)) return json[a];
    return json[b];
  }

  factory TenderRankingRow.fromJson(Map<String, dynamic> json) {
    final proposalId = _pick(json, 'proposal_id', 'proposalId');
    final vendorId = _pick(json, 'vendor_id', 'vendorId');
    final financialTotal = _pick(json, 'financial_total', 'financialTotal');
    final currency = _pick(json, 'currency', 'currency');
    final submittedAt = _pick(json, 'submitted_at', 'submittedAt');
    final rank = _pick(json, 'rank', 'rank');

    return TenderRankingRow(
      proposalId: proposalId.toString(),
      vendorId: vendorId.toString(),
      financialTotal: financialTotal as num,
      currency: (currency ?? 'EGP').toString(),
      submittedAt: DateTime.parse(submittedAt.toString()),
      rank: (rank as num).toInt(),
    );
  }
}
