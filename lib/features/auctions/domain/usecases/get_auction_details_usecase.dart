import '../../data/models/auction.dart';
import '../repositories/auctions_repository.dart';

class GetAuctionDetailsUseCase {
  final AuctionsRepository repo;
  GetAuctionDetailsUseCase(this.repo);

  Future<Auction> call(String id) => repo.getAuctionDetails(id);
}
