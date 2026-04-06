import 'dart:async';
import '../models/auction.dart';
import '../models/bid.dart';

class AuctionsMockApi {
  static const _categories = <String>[
    'Vehicles',
    'Real Estate',
    'Electronics',
    'Industrial',
    'Jewelry',
    'Equipment',
  ];

  static const _departments = <String>[
    'Transport Authority',
    'Public Works',
    'Housing Authority',
    'Customs Authority',
    'IT Department',
    'Supply & Procurement',
  ];

  static const _locations = <String>[
    'Cairo',
    'Giza',
    'Alexandria',
    'Port Said',
    'Suez',
    'Mansoura',
    'Aswan',
  ];

  static const _vehicleTitles = <String>[
    'Toyota Land Cruiser 2019',
    'Nissan Patrol 2018',
    'Hyundai Elantra 2020',
    'Kia Sportage 2017',
    'Isuzu D-Max Pickup 2016',
    'Mitsubishi Pajero 2015',
  ];

  static const _realEstateTitles = <String>[
    'Government Apartment - Nasr City',
    'Administrative Office - Downtown',
    'Warehouse Plot - Industrial Zone',
    'Retail Shop - City Center',
    'Staff Housing Unit - New Cairo',
  ];

  static const _electronicsTitles = <String>[
    'Dell Laptops Batch (30 units)',
    'Desktop PCs Lot (20 units)',
    'Network Switches & Routers Lot',
    'Office Printers Lot (10 units)',
    'Surveillance Monitors Lot',
  ];

  static const _industrialTitles = <String>[
    'Industrial Generator 300KVA',
    'Forklift (Used) - Heavy Duty',
    'Air Compressor Unit',
    'CNC Machine (As-Is)',
    'Workshop Tools Lot',
  ];

  static const _jewelryTitles = <String>[
    'Gold Jewelry Lot (Official Seizure)',
    'Silver Accessories Lot',
    'Luxury Watches Lot',
    'Mixed Jewelry Lot - Certified',
  ];

  static const _equipmentTitles = <String>[
    'Office Furniture Lot',
    'Hospital Equipment Lot',
    'Construction Equipment Lot',
    'Agricultural Equipment Lot',
    'School Supplies Lot',
  ];

  static const _imagePool = <String>[
    'assets/images/auctions/auction_blue_01.jpg',
    'assets/images/auctions/auction_blue_02.jpg',
    'assets/images/auctions/auction_blue_03.jpg',
    'assets/images/auctions/auction_blue_04.jpg',
    'assets/images/auctions/auction_blue_05.jpg',
    'assets/images/auctions/auction_blue_06.jpg',
    'assets/images/auctions/auction_blue_07.jpg',
    'assets/images/auctions/auction_blue_08.jpg',
    'assets/images/auctions/auction_blue_09.jpg',
    'assets/images/auctions/auction_blue_10.jpg',
    'assets/images/auctions/auction_blue_11.jpg',
    'assets/images/auctions/auction_blue_12.jpg',
    'assets/images/auctions/auction_blue_13.jpg',
    'assets/images/auctions/auction_blue_14.jpg',
    'assets/images/auctions/auction_blue_15.jpg',
    'assets/images/auctions/auction_blue_16.jpg',
    'assets/images/auctions/auction_blue_17.jpg',
    'assets/images/auctions/auction_blue_18.jpg',
    'assets/images/auctions/auction_blue_19.jpg',
    'assets/images/auctions/auction_blue_20.jpg',
    'assets/images/auctions/auction_blue_01.jpg',
  ];

  late final List<Auction> _db = _seedAuctions(count: 60);
  final Map<String, List<Bid>> _bids = {};

  List<Auction> _seedAuctions({required int count}) {
    final now = DateTime.now();

    return List.generate(count, (i) {
      final id = '${i + 1}';

      final endTime = (i % 12 == 0)
          ? now.subtract(Duration(hours: 2 + (i % 3))) // ended
          : now.add(Duration(hours: 2 + (i % 10) * 6)); // active

      final startDate = now.subtract(Duration(days: 1 + (i % 4)));

      final category = _categories[i % _categories.length];
      final dept = _departments[(i + 1) % _departments.length];
      final loc = _locations[(i + 2) % _locations.length];

      final title = _titleForCategory(category, i);
      final desc = _descriptionFor(category: category, title: title);

      final startPrice = 25000 + (i * 1850);
      final currentBid = startPrice + (2000 + (i % 8) * 1500);

      final images = _pickImages(i);

      return Auction(
        id: id,
        type: 'Auction', // ✅ ERD: Process.type
        title: title,
        description: desc,
        images: images,
        category: category,
        department: dept,
        location: loc,
        startPrice: startPrice.toDouble(),
        currentBid: currentBid.toDouble(),
        startDate: startDate,
        endTime: endTime,
        status: endTime.isAfter(now) ? 'active' : 'ended',
        isWatchlisted: false,
        createdBy: 'staff_1', // ✅ ERD: created_by
      );
    });
  }

  String _titleForCategory(String category, int i) {
    switch (category) {
      case 'Vehicles':
        return '${_vehicleTitles[i % _vehicleTitles.length]} (Lot #${i + 1})';
      case 'Real Estate':
        return '${_realEstateTitles[i % _realEstateTitles.length]} (Ref #${i + 1})';
      case 'Electronics':
        return '${_electronicsTitles[i % _electronicsTitles.length]} (Lot #${i + 1})';
      case 'Industrial':
        return '${_industrialTitles[i % _industrialTitles.length]} (Lot #${i + 1})';
      case 'Jewelry':
        return '${_jewelryTitles[i % _jewelryTitles.length]} (Case #${i + 1})';
      case 'Equipment':
      default:
        return '${_equipmentTitles[i % _equipmentTitles.length]} (Lot #${i + 1})';
    }
  }

  String _descriptionFor({required String category, required String title}) {
    return 'Official governmental auction listing for: $title.\n\n'
        'Includes inspection notes, legal terms, bidding rules, and payment/collection procedures.\n'
        'Category: $category.\n'
        'All items are sold "as-is" according to auction regulations.';
  }

  List<String> _pickImages(int i) {
    final a = _imagePool[i % _imagePool.length];
    final b = _imagePool[(i + 1) % _imagePool.length];
    final c = _imagePool[(i + 2) % _imagePool.length];

    final set = <String>{a, b, c};
    final list = set.toList();

    if (i % 4 == 0 && list.length >= 3) return list.take(3).toList();
    return list.take(2).toList();
  }

  Future<List<Auction>> getAuctions({
    required int page,
    required int limit,
    String? query,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    var items = List<Auction>.from(_db);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      items = items
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.location.toLowerCase().contains(q) ||
              a.category.toLowerCase().contains(q))
          .toList();
    }

    final start = (page - 1) * limit;
    if (start >= items.length) return [];
    final end = (start + limit).clamp(0, items.length);
    return items.sublist(start, end);
  }

  Future<Auction> getAuctionDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _db.firstWhere((a) => a.id == id);
  }

  Future<List<Bid>> getBidHistory(String auctionId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    _bids.putIfAbsent(auctionId, () {
      final base = (_db.firstWhere((a) => a.id == auctionId).currentBid - 6000)
          .clamp(0, double.infinity);

      return List.generate(8, (i) {
        return Bid(
          id: '${auctionId}_$i',
          auctionId: auctionId,
          userId: 'user_$i',
          amount: (base + (i * 1200)).toDouble(),
          timestamp: DateTime.now().subtract(Duration(minutes: (i + 1) * 9)),
          isWinner: i == 0 ? null : false,
        );
      }).reversed.toList();
    });

    return _bids[auctionId]!;
  }

  Future<Auction> toggleWatchlist(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _db.indexWhere((a) => a.id == id);
    final updated = _db[idx].copyWith(isWatchlisted: !_db[idx].isWatchlisted);
    _db[idx] = updated;
    return updated;
  }

  Future<Auction> placeBid(String id, double amount) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final idx = _db.indexWhere((a) => a.id == id);
    final current = _db[idx];

    if (amount <= current.currentBid) {
      throw Exception('Bid must be higher than current bid');
    }

    final updated = current.copyWith(currentBid: amount);
    _db[idx] = updated;

    final bids = _bids.putIfAbsent(id, () => []);
    bids.insert(
      0,
      Bid(
        id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
        auctionId: id,
        userId: 'me',
        amount: amount,
        timestamp: DateTime.now(),
        isWinner: null,
      ),
    );

    return updated;
  }
}
