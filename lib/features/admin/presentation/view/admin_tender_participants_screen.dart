import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<_TenderParticipantItem> rows = const [];
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
          .map((e) => _TenderParticipantItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final names = await _loadVendorNames(items.map((item) => item.vendorId).toList());
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
    final approved = rows.where((row) => row.status.toLowerCase() == 'approved').length;
    final pending = rows.where((row) => row.status.toLowerCase() == 'pending').length;

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
          _ParticipantsHero(
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
            _StateCard(
              icon: Icons.error_outline,
              title: 'Could not load participants',
              subtitle: error!,
              actionLabel: 'Retry',
              onAction: _load,
              accent: Colors.red,
            )
          else if (rows.isEmpty)
            const _StateCard(
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
                child: _ParticipantCard(
                  item: participant,
                  displayName: vendorNames[participant.vendorId] ?? _shortId(participant.vendorId),
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

class _ParticipantsHero extends StatelessWidget {
  final String tenderId;
  final int total;
  final int approved;
  final int pending;

  const _ParticipantsHero({
    required this.tenderId,
    required this.total,
    required this.approved,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participant Oversight',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review tender participant activity more clearly',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tender ID: $tenderId',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(label: 'Total', value: '$total'),
              _HeroMetric(label: 'Approved', value: '$approved'),
              _HeroMetric(label: 'Pending', value: '$pending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final _TenderParticipantItem item;
  final String displayName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ParticipantCard({
    required this.item,
    required this.displayName,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusChip(text: item.status),
                          _EligibilityChip(eligible: item.eligible),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailLine(
              icon: Icons.schedule_outlined,
              label: 'Reviewed at',
              value: item.reviewedAtLabel,
            ),
            const SizedBox(height: 6),
            _DetailLine(
              icon: Icons.event_outlined,
              label: 'Created at',
              value: item.createdAtLabel,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EligibilityChip extends StatelessWidget {
  final bool eligible;

  const _EligibilityChip({required this.eligible});

  @override
  Widget build(BuildContext context) {
    final color = eligible ? const Color(0xFF0B6E4F) : const Color(0xFFB3261E);
    final text = eligible ? 'Eligible' : 'Not eligible';

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

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final color = switch (lower) {
      'approved' => const Color(0xFF0B6E4F),
      'rejected' => const Color(0xFFB3261E),
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

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: cs.onSurface,
                  ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent = const Color(0xFF0B3C8C),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TenderParticipantItem {
  final String vendorId;
  final String status;
  final bool eligible;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const _TenderParticipantItem({
    required this.vendorId,
    required this.status,
    required this.eligible,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory _TenderParticipantItem.fromMap(Map<String, dynamic> map) {
    return _TenderParticipantItem(
      vendorId: (map['vendor_id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      eligible: (map['eligible'] ?? false) == true,
      reviewedAt: DateTime.tryParse((map['reviewed_at'] ?? '').toString())
          ?.toLocal(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())
          ?.toLocal(),
    );
  }

  String get reviewedAtLabel => _format(reviewedAt);
  String get createdAtLabel => _format(createdAt);

  static String _format(DateTime? value) {
    if (value == null) return '-';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}
