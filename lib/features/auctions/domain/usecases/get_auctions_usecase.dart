import '../../data/models/auction.dart';
import '../repositories/auctions_repository.dart';

class GetAuctionsUseCase {
  final AuctionsRepository repo;
  GetAuctionsUseCase(this.repo);

  Future<List<Auction>> call({
    required int page,
    required int limit,
    String? query,
  }) {
    return repo.getAuctions(page: page, limit: limit, query: query);
  }
}
