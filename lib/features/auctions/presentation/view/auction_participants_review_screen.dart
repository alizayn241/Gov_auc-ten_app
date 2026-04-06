import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/admin_auction_participant.dart';
import '../../data/sources/auctions_admin_remote_data_source.dart';

class AuctionParticipantsReviewScreen extends StatefulWidget {
  final String auctionId;
  const AuctionParticipantsReviewScreen({super.key, required this.auctionId});

  @override
  State<AuctionParticipantsReviewScreen> createState() =>
      _AuctionParticipantsReviewScreenState();
}

class _AuctionParticipantsReviewScreenState
    extends State<AuctionParticipantsReviewScreen> {
  bool loading = true;
  String? error;
  List<_ParticipantViewData> items = const [];

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final participants = await _remote.getParticipants(widget.auctionId);
      final userIds = participants.map((p) => p.userId).toSet().toList();

      final profileMap = <String, _ProfileMini>{};
      if (userIds.isNotEmpty) {
        try {
          final adminUsers = await Supabase.instance.client.rpc('admin_list_users');
          if (adminUsers is List) {
            for (final row in adminUsers) {
              final map = Map<String, dynamic>.from(row as Map);
              final id = ((map['user_id'] ?? map['id']) ?? '').toString();
              if (id.isEmpty || !userIds.contains(id)) continue;
              profileMap[id] = _ProfileMini.fromMap(map);
            }
          }
        } catch (_) {
          // Fall back to public profiles below when admin RPC is unavailable.
        }

        final missingIds = userIds
            .where((id) => !profileMap.containsKey(id))
            .toList();

        if (missingIds.isNotEmpty) {
          final profileRows = await Supabase.instance.client
              .from('profiles')
              .select('*')
              .inFilter('id', missingIds);

          for (final row in (profileRows as List)) {
            final map = Map<String, dynamic>.from(row as Map);
            final id = (map['id'] ?? '').toString();
            profileMap[id] = _ProfileMini.fromMap(map);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        items = participants
            .map((p) => _ParticipantViewData(
                  participant: p,
                  profile: profileMap[p.userId],
                ))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _review({
    required String userId,
    required String status,
  }) async {
    try {
      await _remote.reviewParticipant(
        auctionId: widget.auctionId,
        userId: userId,
        status: status,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Participant updated: $status',
              'تم تحديث حالة المشارك: $status',
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _fmt(DateTime? d) => d == null ? '-' : d.toLocal().toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Participants Review', 'مراجعة المشاركين')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : error != null
              ? Center(child: Text(error!))
              : items.isEmpty
                  ? Center(child: Text(context.tr('No participants yet', 'لا يوجد مشاركون بعد')))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final row = items[i];
                        final p = row.participant;
                        final profile = row.profile;
                        final title = profile?.displayName.isNotEmpty == true
                            ? profile!.displayName
                            : context.tr('User ${_shortId(p.userId)}', 'مستخدم ${_shortId(p.userId)}');

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary.withOpacity(.10),
                                      child: Icon(
                                        Icons.person,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            context.tr('User ID: ${_shortId(p.userId)}', 'معرف المستخدم: ${_shortId(p.userId)}'),
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _StatusChip(text: p.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (profile != null) ...[
                                  Text(context.tr('Account Type: ${profile.accountType}', 'نوع الحساب: ${profile.accountType}')),
                                  Text(context.tr('KYC Status: ${profile.kycStatus}', 'حالة التحقق: ${profile.kycStatus}')),
                                  Text(context.tr('Role: ${profile.role}', 'الدور: ${profile.role}')),
                                  const SizedBox(height: 6),
                                ],
                                Text(context.tr('Eligible: ${p.eligible ? "YES" : "NO"}', 'مؤهل: ${p.eligible ? "نعم" : "لا"}')),
                                Text(context.tr('Reviewed at: ${_fmt(p.reviewedAt)}', 'تمت المراجعة في: ${_fmt(p.reviewedAt)}')),
                                Text(context.tr('Created at: ${_fmt(p.createdAt)}', 'تاريخ الإنشاء: ${_fmt(p.createdAt)}')),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: p.status == 'approved'
                                            ? null
                                            : () => _review(
                                                  userId: p.userId,
                                                  status: 'approved',
                                                ),
                                        child: Text(context.tr('Approve', 'موافقة')),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: p.status == 'rejected'
                                            ? null
                                            : () => _review(
                                                  userId: p.userId,
                                                  status: 'rejected',
                                                ),
                                        child: Text(context.tr('Reject', 'رفض')),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  static String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}

class _ParticipantViewData {
  final AdminAuctionParticipant participant;
  final _ProfileMini? profile;

  const _ParticipantViewData({
    required this.participant,
    required this.profile,
  });
}

class _ProfileMini {
  final String displayName;
  final String role;
  final String accountType;
  final String kycStatus;

  const _ProfileMini({
    required this.displayName,
    required this.role,
    required this.accountType,
    required this.kycStatus,
  });

  factory _ProfileMini.fromMap(Map<String, dynamic> map) {
    final displayName = _firstNonEmpty([
      map['display_name'],
      map['name'],
      map['full_name'],
      map['username'],
      map['email'],
      map['id'],
    ]);

    return _ProfileMini(
      displayName: displayName,
      role: (map['role'] ?? 'citizen').toString(),
      accountType: (map['account_type'] ?? 'individual').toString(),
      kycStatus: (map['kyc_status'] ?? 'pending').toString(),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final color = switch (lower) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => const Color(0xFF7A5D00),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
