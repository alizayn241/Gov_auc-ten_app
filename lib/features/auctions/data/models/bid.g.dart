// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bid.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bid _$BidFromJson(Map<String, dynamic> json) => Bid(
      id: json['id'] as String,
      auctionId: json['auctionId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['created_at'] as String),
      isWinner: json['is_winner'] as bool?,
    );

Map<String, dynamic> _$BidToJson(Bid instance) => <String, dynamic>{
      'id': instance.id,
      'auctionId': instance.auctionId,
      'userId': instance.userId,
      'amount': instance.amount,
      'created_at': instance.timestamp.toIso8601String(),
      'is_winner': instance.isWinner,
    };
