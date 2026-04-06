import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract interface for user-facing auctions remote data source
abstract class AuctionsRemoteDataSource {
  Future<List<Map<String, dynamic>>> getAuctions({
    required int page,
    required int limit,
    String? query,
  });

  Future<Map<String, dynamic>> getAuctionDetails(String id);

  Future<List<Map<String, dynamic>>> getBidHistory(String auctionId);

  Future<Map<String, dynamic>> placeBid(String auctionId, double amount);

  Future<void> toggleWatchlist(String auctionId);

  Future<List<Map<String, dynamic>>> getWatchlistAuctions();

  Future<List<Map<String, dynamic>>> getMyBids();

  Future<List<Map<String, dynamic>>> getAuctionsByIds(List<String> ids);
}

class SupabaseAuctionsRemoteDataSource implements AuctionsRemoteDataSource {
  final SupabaseClient sb;

  SupabaseAuctionsRemoteDataSource(this.sb);

  /// ==============================
  /// Get Auctions List (with paging)
  /// ==============================
  @override
  Future<List<Map<String, dynamic>>> getAuctions({
    required int page,
    required int limit,
    String? query,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit - 1;

    dynamic q = sb
        .from('auctions')
        .select('*')
        .order('created_at', ascending: false)
        .range(from, to);

    // optional search
    if (query != null && query.trim().isNotEmpty) {
      q = sb
          .from('auctions')
          .select('*')
          .ilike('title', '%${query.trim()}%')
          .order('created_at', ascending: false)
          .range(from, to);
    }

    final res = await q;

    return (res as List)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  /// ==============================
  /// Get Auction Details
  /// ==============================
  @override
  Future<Map<String, dynamic>> getAuctionDetails(String id) async {
    final res = await sb
        .from('auctions')
        .select('*')
        .eq('id', id)
        .single();

    return Map<String, dynamic>.from(res);
  }

  /// ==============================
  /// Bid History
  /// ==============================
  @override
  Future<List<Map<String, dynamic>>> getBidHistory(String auctionId) async {
    final res = await sb
        .from('bids')
        .select('*')
        .eq('auction_id', auctionId)
        .order('created_at', ascending: false)
        .limit(30);

    return (res as List)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  /// ==============================
  /// Place Bid
  /// ==============================
  @override
  Future<Map<String, dynamic>> placeBid(String auctionId, double amount) async {
    final uid = sb.auth.currentUser?.id;

    if (uid == null) {
      throw Exception('Please login to place a bid');
    }

    final existingParticipant = await sb
        .from('auction_participants')
        .select('id')
        .eq('auction_id', auctionId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existingParticipant == null) {
      await sb.from('auction_participants').insert({
        'auction_id': auctionId,
        'user_id': uid,
        'status': 'pending',
        'eligible': false,
      });
    }

    await sb.from('bids').insert({
      'auction_id': auctionId,
      'user_id': uid,
      'amount': amount,
    });

    // return updated auction
    return getAuctionDetails(auctionId);
  }

  /// ==============================
  /// Toggle Watchlist
  /// ==============================
  @override
  Future<void> toggleWatchlist(String auctionId) async {
    final uid = sb.auth.currentUser?.id;

    if (uid == null) {
      throw Exception('Please login');
    }

    try {
      final existing = await sb
          .from('watchlist')
          .select('id')
          .eq('user_id', uid)
          .eq('auction_id', auctionId)
          .maybeSingle();

      if (existing != null) {
        await sb.from('watchlist').delete().eq('id', existing['id']);
      } else {
        await sb.from('watchlist').insert({
          'user_id': uid,
          'auction_id': auctionId,
        });
      }
    } on PostgrestException catch (e) {
      if (e.message.contains("public.watchlist")) {
        return;
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getWatchlistAuctions() async {
    try {
      final res = await sb.rpc('get_my_watchlist_auctions');
      return (res as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    } on PostgrestException {
      final uid = sb.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Please login');
      }

      final watchlistRows = await sb
          .from('watchlist')
          .select('auction_id')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final auctionIds = (watchlistRows as List)
          .map((row) => row['auction_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (auctionIds.isEmpty) {
        return const [];
      }

      final auctions = await sb
          .from('auctions')
          .select('*')
          .inFilter('id', auctionIds);

      final rows = (auctions as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

      rows.sort((a, b) {
        final aIndex = auctionIds.indexOf(a['id']?.toString() ?? '');
        final bIndex = auctionIds.indexOf(b['id']?.toString() ?? '');
        return aIndex.compareTo(bIndex);
      });

      return rows;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMyBids() async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Please login to view your bids');
    }

    final res = await sb
        .from('bids')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (res as List)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAuctionsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];

    final res = await sb.from('auctions').select('*').inFilter('id', ids);

    return (res as List)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }
}
