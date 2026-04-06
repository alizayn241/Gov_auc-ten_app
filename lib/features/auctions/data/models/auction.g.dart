// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Auction _$AuctionFromJson(Map<String, dynamic> json) => Auction(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'Auction',
      title: json['title'] as String,
      description: json['description'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      category: json['category'] as String,
      department: json['department'] as String,
      location: json['location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startPrice: (json['startPrice'] as num).toDouble(),
      currentBid: (json['currentBid'] as num).toDouble(),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] as String,
      isWatchlisted: json['isWatchlisted'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$AuctionToJson(Auction instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'images': instance.images,
      'category': instance.category,
      'department': instance.department,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'startPrice': instance.startPrice,
      'currentBid': instance.currentBid,
      'startDate': instance.startDate?.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'status': instance.status,
      'isWatchlisted': instance.isWatchlisted,
      'created_by': instance.createdBy,
    };
