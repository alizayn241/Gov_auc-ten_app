import 'package:json_annotation/json_annotation.dart';

part 'auction.g.dart';

@JsonSerializable()
class Auction {
  final String id;
  final String type;
  final String title;
  final String description;
  final List<String> images;
  final String category;
  final String department;
  final String location;
  final double? latitude;
  final double? longitude;

  @JsonKey(name: 'start_price')
  final double startPrice;

  @JsonKey(name: 'current_bid')
  final double currentBid;

  @JsonKey(name: 'start_date')
  final DateTime? startDate;

  @JsonKey(name: 'end_time')
  final DateTime endTime;

  final String status;

  @JsonKey(name: 'is_watchlisted')
  final bool isWatchlisted;

  @JsonKey(name: 'created_by')
  final String? createdBy;

  const Auction({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.images,
    required this.category,
    required this.department,
    required this.location,
    this.latitude,
    this.longitude,
    required this.startPrice,
    required this.currentBid,
    this.startDate,
    required this.endTime,
    required this.status,
    required this.isWatchlisted,
    this.createdBy,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['image_url']?.toString();
    final imagesValue = json['images'];
    final imagesList = imagesValue is List
        ? List<String>.from(
            imagesValue.map((e) => e.toString()).where((e) => e.isNotEmpty),
          )
        : const <String>[];

    return Auction(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'Auction').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      images: imagesList.isNotEmpty
          ? imagesList
          : (imageUrl == null || imageUrl.isEmpty)
              ? const []
              : [imageUrl],
      category: (json['category'] ?? 'Other').toString(),
      department: (json['department'] ?? 'Government').toString(),
      location: (json['location'] ?? 'Government Asset').toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startPrice: (json['start_price'] as num?)?.toDouble() ?? 0.0,
      currentBid: (json['current_bid'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] == null
          ? null
          : DateTime.tryParse(json['start_date'].toString()),
      endTime: DateTime.parse(json['end_time'].toString()),
      status: (json['status'] ?? 'draft').toString(),
      isWatchlisted: (json['is_watchlisted'] ?? false) == true,
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$AuctionToJson(this);

  Auction copyWith({
    double? currentBid,
    bool? isWatchlisted,
    String? status,
    List<String>? images,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return Auction(
      id: id,
      type: type,
      title: title,
      description: description,
      images: images ?? this.images,
      category: category,
      department: department,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startPrice: startPrice,
      currentBid: currentBid ?? this.currentBid,
      startDate: startDate,
      endTime: endTime,
      status: status ?? this.status,
      isWatchlisted: isWatchlisted ?? this.isWatchlisted,
      createdBy: createdBy,
    );
  }

  double get minimumPrice => startPrice;
  DateTime get endDate => endTime;
}
