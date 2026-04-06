import '../../data/models/auction.dart';
import '../../data/models/bid.dart';

class AuctionsState {
  final bool loading;
  final String? error;
  final List<Auction> items;
  final int page;
  final bool hasMore;
  final String query;

  // ✅ NEW: bids placed by current user (for instant My Bids screen)
  final List<Bid> myBids;

  const AuctionsState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.query = '',
    this.myBids = const [],
  });

  AuctionsState copyWith({
    bool? loading,
    String? error,
    List<Auction>? items,
    int? page,
    bool? hasMore,
    String? query,
    List<Bid>? myBids,
  }) {
    return AuctionsState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      myBids: myBids ?? this.myBids,
    );
  }
}