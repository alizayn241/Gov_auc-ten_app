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

  RealtimeChannel watchAuctionStatus({
    required String auctionId,
    required void Function(String newStatus) onStatusChange,
  }) {
    final channel = sb.channel('realtime:auction-status:$auctionId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'auctions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: auctionId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            final oldData = payload.oldRecord;

            if (newData != null && oldData != null) {
              final newStatus = (newData['status'] ?? '').toString();
              final oldStatus = (oldData['status'] ?? '').toString();

              if (newStatus != oldStatus) {
                onStatusChange(newStatus);
              }
            }
          },
        )
        .subscribe();

    return channel;
  }

  RealtimeChannel watchNotifications({
    required String userId,
    required void Function() onNewNotification,
  }) {
    final channel = sb.channel('realtime:notifications:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onNewNotification(),
        )
        .subscribe();

    return channel;
  }

  void unsubscribe(RealtimeChannel? channel) {
    if (channel == null) return;
    sb.removeChannel(channel);
  }
}