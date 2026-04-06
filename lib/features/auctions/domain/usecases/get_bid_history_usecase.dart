import '../repositories/auctions_repository.dart';
import '../../data/models/bid.dart';

class GetBidHistoryUseCase {
  final AuctionsRepository repo;
  GetBidHistoryUseCase(this.repo);

  Future<List<Bid>> call(String auctionId) => repo.getBidHistory(auctionId);
}