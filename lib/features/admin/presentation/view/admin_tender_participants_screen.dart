import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tender_participants/tender_participants_models.dart';
import 'tender_participants/tender_participants_widgets.dart';

class AdminTenderParticipantsScreen extends StatefulWidget {
  final String tenderId;

  const AdminTenderParticipantsScreen({super.key, required this.tenderId});

  @override
  State<AdminTenderParticipantsScreen> createState() =>
      _AdminTenderParticipantsScreenState();
}

class _AdminTenderParticipantsScreenState
    extends State<AdminTenderParticipantsScreen> {
  bool loading = true;
  String? error;
  List<TenderParticipantItem> rows = const [];
  Map<String, String> vendorNames = const {};

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
      final res = await Supabase.instance.client
          .from('tender_participants')
          .select('vendor_id,status,eligible,reviewed_at,created_at')
          .eq('tender_id', widget.tenderId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      final items = (res as List)
          .map(
            (e) => TenderParticipantItem.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList();
      final names = await _loadVendorNames(
        items.map((item) => item.vendorId).toList(),
      );
      if (!mounted) return;
      setState(() {
        rows = items;
        vendorNames = names;
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

  Future<void> _reviewParticipant({
    required String vendorId,
    required bool approve,
  }) async {
    try {
      await Supabase.instance.client
          .from('tender_participants')
          .update({
            'status': approve ? 'approved' : 'rejected',
            'eligible': approve,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('tender_id', widget.tenderId)
          .eq('vendor_id', vendorId);

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Participant approved successfully'
                : 'Participant rejected successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final approved = rows
        .where((row) => row.status.toLowerCase() == 'approved')
        .length;
    final pending = rows
        .where((row) => row.status.toLowerCase() == 'pending')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tender Participants'),
        leading: const AppPageBackButton(fallbackRoute: '/admin/tenders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminTenderParticipantsHero(
            tenderId: widget.tenderId,
            total: rows.length,
            approved: approved,
            pending: pending,
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (error != null)
            TenderParticipantsStateCard(
              icon: Icons.error_outline,
              title: 'Could not load participants',
              subtitle: error!,
              actionLabel: 'Retry',
              onAction: _load,
              accent: Colors.red,
            )
          else if (rows.isEmpty)
            const TenderParticipantsStateCard(
              icon: Icons.groups_outlined,
              title: 'No participants yet',
              subtitle:
                  'Submitted vendor entries for this tender will appear here for review.',
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${rows.length} participants',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            ...rows.map(
              (participant) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TenderParticipantCard(
                  item: participant,
                  displayName:
                      vendorNames[participant.vendorId] ??
                          _shortId(participant.vendorId),
                  onApprove: participant.status.toLowerCase() == 'approved'
                      ? null
                      : () => _reviewParticipant(
                            vendorId: participant.vendorId,
                            approve: true,
                          ),
                  onReject: participant.status.toLowerCase() == 'rejected'
                      ? null
                      : () => _reviewParticipant(
                            vendorId: participant.vendorId,
                            approve: false,
                          ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, String>> _loadVendorNames(List<String> ids) async {
    final uniqueIds = ids.toSet().toList();
    if (uniqueIds.isEmpty) return const {};

    final map = <String, String>{};

    try {
      final adminUsers = await Supabase.instance.client.rpc('admin_list_users');
      if (adminUsers is List) {
        for (final row in adminUsers) {
          final item = Map<String, dynamic>.from(row as Map);
          final id = ((item['user_id'] ?? item['id']) ?? '').toString();
          if (id.isEmpty || !uniqueIds.contains(id)) continue;
          map[id] = _resolveDisplayName(item);
        }
      }
    } catch (_) {
      // Fall back to public profiles below when admin RPC is unavailable.
    }

    final missingIds = uniqueIds.where((id) => !map.containsKey(id)).toList();
    if (missingIds.isEmpty) {
      return map;
    }

    final res = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .inFilter('id', missingIds);

    for (final row in (res as List)) {
      final item = Map<String, dynamic>.from(row as Map);
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;
      map[id] = _resolveDisplayName(item);
    }
    return map;
  }

  String _resolveDisplayName(Map<String, dynamic> map) {
    for (final value in [
      map['display_name'],
      map['name'],
      map['full_name'],
      map['username'],
      map['email'],
      map['id'],
    ]) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return 'User';
  }

  static String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}
