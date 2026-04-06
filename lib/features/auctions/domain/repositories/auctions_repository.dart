import '../../data/models/auction.dart';
import '../../data/models/bid.dart';

abstract class AuctionsRepository {
  Future<List<Auction>> getAuctions({required int page, required int limit, String? query});
  Future<Auction> getAuctionDetails(String id);

  Future<List<Bid>> getBidHistory(String auctionId);

  Future<Auction> placeBid(String auctionId, double amount);

  Future<void> toggleWatchlist(String auctionId);

  Future<List<Auction>> getWatchlistAuctions();

  Future<List<Bid>> getMyBids();

  Future<List<Auction>> getAuctionsByIds(List<String> ids);
}
