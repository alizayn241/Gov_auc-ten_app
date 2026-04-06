import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRealtimeService {
  final SupabaseClient sb;
  SupabaseRealtimeService(this.sb);

  RealtimeChannel watchBidsForAuction({
    required String auctionId,
    required void Function() onChange,
  }) {
    final channel = sb.channel('realtime:bids:$auctionId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bids',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'auction_id',
            value: auctionId,
          ),
          callback: (payload) => onChange(),
        )
        .subscribe();

    return channel;
  }

  void unsubscribe(RealtimeChannel? channel) {
    if (channel == null) return;
    sb.removeChannel(channel);
  }
}