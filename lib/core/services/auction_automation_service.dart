import 'package:supabase_flutter/supabase_flutter.dart';

class AuctionAutomationService {
  final SupabaseClient _sb;

  AuctionAutomationService(this._sb);

  /// Manually trigger the expired auctions check
  /// This is useful for development/testing when pg_cron is not available
  Future<Map<String, dynamic>> checkExpiredAuctions() async {
    try {
      final result = await _sb.rpc('check_expired_auctions');
      return {
        'success': true,
        'message': 'Auction check completed',
        'result': result,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get statistics about expired auctions
  Future<Map<String, dynamic>> getExpiredAuctionsStats() async {
    try {
      final result = await _sb
          .from('auctions')
          .select('id, title, end_time, status')
          .lt('end_time', DateTime.now().toUtc().toIso8601String())
          .neq('status', 'finalized')
          .neq('status', 'cancelled');

      return {
        'success': true,
        'expired_auctions_count': result.length,
        'expired_auctions': result
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Force finalize a specific auction (admin only)
  Future<Map<String, dynamic>> forceFinalizeAuction(String auctionId) async {
    try {
      final result = await _sb.rpc('finalize_auction', params: {
        'p_auction_id': auctionId,
      });

      return {'success': true, 'result': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
