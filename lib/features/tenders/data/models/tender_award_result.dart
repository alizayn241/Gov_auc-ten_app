class TenderAwardResult {
  final String tenderId;
  final String winnerVendorId;
  final num winningTotal;
  final String proposalId;

  TenderAwardResult({
    required this.tenderId,
    required this.winnerVendorId,
    required this.winningTotal,
    required this.proposalId,
  });

  static dynamic _pick(Map<String, dynamic> json, String a, String b) {
    if (json.containsKey(a)) return json[a];
    return json[b];
  }

  factory TenderAwardResult.fromJson(Map<String, dynamic> json) {
    final tenderId = _pick(json, 'tenderId', 'tender_id');
    final winnerVendorId = _pick(json, 'winnerVendorId', 'winner_vendor_id');
    final winningTotal = _pick(json, 'winningTotal', 'winning_total');
    final proposalId = _pick(json, 'proposalId', 'proposal_id');

    return TenderAwardResult(
      tenderId: tenderId.toString(),
      winnerVendorId: winnerVendorId.toString(),
      winningTotal: winningTotal as num,
      proposalId: proposalId.toString(),
    );
  }
}