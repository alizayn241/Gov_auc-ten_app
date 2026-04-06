import 'package:json_annotation/json_annotation.dart';

part 'bid.g.dart';

@JsonSerializable()
class Bid {
  final String id;

  @JsonKey(name: 'auction_id')
  final String auctionId;

  @JsonKey(name: 'user_id')
  final String userId;

  final double amount;

  @JsonKey(name: 'created_at')
  final DateTime timestamp;

  @JsonKey(name: 'is_winner')
  final bool? isWinner;

  Bid({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.amount,
    required this.timestamp,
    this.isWinner,
  });

  String get processId => auctionId;

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: (json['id'] ?? '').toString(),
      auctionId: (json['auction_id'] ?? json['auctionId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'].toString()),
      isWinner: json['is_winner'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => _$BidToJson(this);
}
