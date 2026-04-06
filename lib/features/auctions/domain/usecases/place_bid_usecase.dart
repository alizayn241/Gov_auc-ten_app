import '../../data/models/auction.dart';
import '../repositories/auctions_repository.dart';

class PlaceBidUseCase {
  final AuctionsRepository repo;
  PlaceBidUseCase(this.repo);

  Future<Auction> call(String id, double amount) => repo.placeBid(id, amount);
}
