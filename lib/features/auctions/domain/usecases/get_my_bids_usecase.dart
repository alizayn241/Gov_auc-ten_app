import '../repositories/auctions_repository.dart';
import '../../data/models/bid.dart';

class GetMyBidsUseCase {
  final AuctionsRepository repo;
  GetMyBidsUseCase(this.repo);

  Future<List<Bid>> call() => repo.getMyBids();
}