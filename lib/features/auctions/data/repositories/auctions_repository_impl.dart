import '../../domain/repositories/auctions_repository.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../sources/auctions_supabase_data_source.dart';

class AuctionsRepositoryImpl implements AuctionsRepository {
  final AuctionsRemoteDataSource remote;

  AuctionsRepositoryImpl(this.remote);

  @override
  Future<List<Auction>> getAuctions({
    required int page,
    required int limit,
    String? query,
  }) async {
    final rows = await remote.getAuctions(page: page, limit: limit, query: query);

    // ✅ prevents List<Object>
    return rows.map((r) => Auction.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  @override
  Future<Auction> getAuctionDetails(String id) async {
    final row = await remote.getAuctionDetails(id);
    return Auction.fromJson(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<List<Bid>> getBidHistory(String auctionId) async {
    final rows = await remote.getBidHistory(auctionId);
    return rows.map((r) => Bid.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  @override
  Future<Auction> placeBid(String auctionId, double amount) async {
    await remote.placeBid(auctionId, amount);
    final row = await remote.getAuctionDetails(auctionId);
    return Auction.fromJson(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<void> toggleWatchlist(String auctionId) => remote.toggleWatchlist(auctionId);

  // لو عندك دول في repo interface وعايزهم من Supabase: نكمّلهم بعدين
  @override
  Future<List<Auction>> getWatchlistAuctions() async {
    final rows = await remote.getWatchlistAuctions();
    return rows
        .map((r) => Auction.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<List<Bid>> getMyBids() async {
    final rows = await remote.getMyBids();
    return rows
        .map((r) => Bid.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<List<Auction>> getAuctionsByIds(List<String> ids) async {
    final rows = await remote.getAuctionsByIds(ids);
    return rows
        .map((r) => Auction.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }
}
