import '../repositories/auctions_repository.dart';
import '../../data/models/auction.dart';

class GetWatchlistUseCase {
  final AuctionsRepository repo;
  GetWatchlistUseCase(this.repo);

  Future<List<Auction>> call() => repo.getWatchlistAuctions();
}