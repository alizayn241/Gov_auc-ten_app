import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auctions_repository_impl.dart';
import '../../domain/repositories/auctions_repository.dart';
import '../../data/sources/auctions_supabase_data_source.dart';
import '../../data/models/bid.dart';
import '../../data/models/auction.dart';

// ✅ repo provider
final auctionsRepositoryProvider = Provider<AuctionsRepository>((ref) {
  final ds = SupabaseAuctionsRemoteDataSource(Supabase.instance.client);
  return AuctionsRepositoryImpl(ds);
});

// ✅ Bid history (family)
final bidHistoryProvider = FutureProvider.family<List<Bid>, String>((ref, auctionId) async {
  final repo = ref.watch(auctionsRepositoryProvider);
  return repo.getBidHistory(auctionId);
});

// ✅ Watchlist
final watchlistProvider = FutureProvider<List<Auction>>((ref) async {
  final repo = ref.watch(auctionsRepositoryProvider);
  return repo.getWatchlistAuctions();
});

// ✅ My bids
final myBidsProvider = FutureProvider<List<Bid>>((ref) async {
  final repo = ref.watch(auctionsRepositoryProvider);
  return repo.getMyBids();
});

final myBidAuctionsProvider =
    FutureProvider.family<Map<String, Auction>, String>((ref, idsKey) async {
  if (idsKey.isEmpty) return const {};

  final repo = ref.watch(auctionsRepositoryProvider);
  final ids = idsKey.split('|').where((id) => id.isNotEmpty).toList();
  final auctions = await repo.getAuctionsByIds(ids);
  return {
    for (final auction in auctions) auction.id: auction,
  };
});
