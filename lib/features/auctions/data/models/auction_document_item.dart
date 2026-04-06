class AuctionDocumentItem {
  final String id;
  final String auctionId;
  final String path;
  final String docType;
  final String visibility;
  final String? createdBy;
  final DateTime createdAt;

  AuctionDocumentItem({
    required this.id,
    required this.auctionId,
    required this.path,
    required this.docType,
    required this.visibility,
    required this.createdBy,
    required this.createdAt,
  });

  factory AuctionDocumentItem.fromJson(Map<String, dynamic> json) {
    return AuctionDocumentItem(
      id: json['id'].toString(),
      auctionId: json['auction_id'].toString(),
      path: (json['path'] ?? '').toString(),
      docType: (json['doc_type'] ?? '').toString(),
      visibility: (json['visibility'] ?? 'public').toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}