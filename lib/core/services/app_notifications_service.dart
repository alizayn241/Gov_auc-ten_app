import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotificationsService {
  final SupabaseClient sb;

  AppNotificationsService(this.sb);

  Future<void> createAuctionCreatedNotification({
    required String auctionId,
    required String title,
    required String category,
  }) async {
    await _createAudienceNotification(
      title: 'New auction available',
      body: '$title was added in $category.',
      type: 'auction_created',
      entityType: 'auction',
      entityId: auctionId,
    );
  }

  Future<void> createTenderCreatedNotification({
    required String tenderId,
    required String title,
    String? entity,
    String? referenceNo,
  }) async {
    final details = [
      if (entity != null && entity.trim().isNotEmpty) entity.trim(),
      if (referenceNo != null && referenceNo.trim().isNotEmpty)
        'Ref ${referenceNo.trim()}',
    ].join(' | ');

    await _createAudienceNotification(
      title: 'New tender available',
      body: details.isEmpty ? title : '$title - $details',
      type: 'tender_created',
      entityType: 'tender',
      entityId: tenderId,
    );
  }

  Future<List<Map<String, dynamic>>> listNotificationsForCurrentUser() async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Please login first');
    }

    final rows = await sb
        .from('notifications')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Please login first');
    }

    await sb
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', uid);
  }

  Future<void> _createAudienceNotification({
    required String title,
    required String body,
    required String type,
    required String entityType,
    required String entityId,
  }) async {
    final profiles = await sb
        .from('profiles')
        .select('id,role')
        .eq('role', 'citizen');

    final recipients = (profiles as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map((row) => (row['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    if (recipients.isEmpty) return;

    await sb.from('notifications').insert(
          recipients
              .map(
                (userId) => {
                  'user_id': userId,
                  'title': title,
                  'body': body,
                  'type': type,
                  'entity_type': entityType,
                  'entity_id': entityId,
                },
              )
              .toList(),
        );
  }
}
