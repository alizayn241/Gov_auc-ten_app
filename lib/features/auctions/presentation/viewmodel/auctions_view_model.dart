import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/features/auctions/data/sources/auctions_remote_data_source.dart';
import 'package:gov_auction_app/features/auth/data/sources/auth_remote_data_source.dart' hide AuctionsRemoteDataSource;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/sources/auctions_supabase_data_source.dart';
import '../viewmodel/auctions_state.dart';
import '../../data/repositories/auctions_repository_impl.dart';
import '../../domain/repositories/auctions_repository.dart';
import '../../domain/usecases/get_auctions_usecase.dart';
import '../../domain/usecases/get_auction_details_usecase.dart';
import '../../domain/usecases/place_bid_usecase.dart';
import '../../data/models/auction.dart';
import '../../data/models/bid.dart';

// ✅ CHANGED: use the combined remote data source file
import '../../data/sources/auctions_remote_data_source.dart' hide AuctionsRemoteDataSource;

import '../../../auth/presentation/viewmodel/auth_view_model.dart';

final auctionsRepositoryProvider = Provider<AuctionsRepository>((ref) {
  final remote = SupabaseAuctionsRemoteDataSource(Supabase.instance.client);
  return AuctionsRepositoryImpl(remote as AuctionsRemoteDataSource);
});

final auctionsViewModelProvider =
    StateNotifierProvider<AuctionsViewModel, AuctionsState>((ref) {
  final repo = ref.watch(auctionsRepositoryProvider);
  return AuctionsViewModel(
    getAuctions: GetAuctionsUseCase(repo),
    getDetails: GetAuctionDetailsUseCase(repo),
    placeBid: PlaceBidUseCase(repo),
    repo: repo,
    ref: ref,
  )..loadInitial();
});

class AuctionsViewModel extends StateNotifier<AuctionsState> {
  final GetAuctionsUseCase getAuctions;
  final GetAuctionDetailsUseCase getDetails;
  final PlaceBidUseCase placeBid;
  final AuctionsRepository repo;
  final Ref ref;

  static const _limit = 50;

  AuctionsViewModel({
    required this.getAuctions,
    required this.getDetails,
    required this.placeBid,
    required this.repo,
    required this.ref,
  }) : super(const AuctionsState());

  Future<void> loadInitial({String query = ''}) async {
    state = state.copyWith(
      loading: true,
      error: null,
      items: const [],
      page: 1,
      hasMore: true,
      query: query,
    );

    try {
      final items = <Auction>[];
      var page = 1;
      var hasMore = true;

      while (hasMore) {
        final batch = await getAuctions(page: page, limit: _limit, query: query);
        items.addAll(batch);
        hasMore = batch.length == _limit;
        page++;
      }

      state = state.copyWith(
        loading: false,
        items: items,
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;

    state = state.copyWith(loading: true, error: null);

    try {
      final nextPage = state.page + 1;
      final items = await getAuctions(
        page: nextPage,
        limit: _limit,
        query: state.query,
      );

      state = state.copyWith(
        loading: false,
        page: nextPage,
        items: [...state.items, ...items],
        hasMore: items.length == _limit,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Auction> fetchDetails(String id) => getDetails(id);

  Future<List<Bid>> fetchBidHistory(String id) => repo.getBidHistory(id);

  Future<void> toggleWatch(String auctionId) async {
    final auth = ref.read(authViewModelProvider);
    if (!auth.isAuthenticated) {
      throw Exception('Please login to manage your watchlist');
    }
    if (auth.isAdmin) {
      throw Exception('Admin accounts cannot use the watchlist');
    }

    await repo.toggleWatchlist(auctionId);

    // ✅ تحديث UI فورًا (محليًا) بدون انتظار refetch
    state = state.copyWith(
      items: state.items.map((a) {
        if (a.id != auctionId) return a;
        return a.copyWith(isWatchlisted: !a.isWatchlisted);
      }).toList(),
    );
  }

  /// ✅ Submit bid + تحديث فوري:
  /// 1) تحديث currentBid داخل items
  /// 2) إضافة bid إلى myBids فوراً
  Future<Auction> submitBid(String auctionId, double amount) async {
    final auth = ref.read(authViewModelProvider);
    if (!auth.isAuthenticated) {
      throw Exception('Please login to place a bid');
    }
    if (auth.isAdmin) {
      throw Exception('Admin accounts cannot place bids');
    }

    final updated = await placeBid(auctionId, amount);

    // ✅ Update auctions list instantly
    final updatedItems =
        state.items.map((a) => a.id == auctionId ? updated : a).toList();

    // ✅ Fix uid undefined
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'me';

    final newBid = Bid(
      id: '${auctionId}_${DateTime.now().millisecondsSinceEpoch}',
      auctionId: auctionId,
      userId: uid,
      amount: amount,
      timestamp: DateTime.now(),
      isWinner: null,
    );

    // ✅ Deduplicate
    final exists = state.myBids.any((b) => b.id == newBid.id);

    state = state.copyWith(
      items: updatedItems,
      myBids: exists ? state.myBids : [newBid, ...state.myBids],
    );

    return updated;
  }

  Future<void> refresh() async {
    await loadInitial(query: state.query);
  }
}
