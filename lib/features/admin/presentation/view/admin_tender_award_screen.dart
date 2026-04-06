import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tenders/data/models/tender.dart';
import '../../../tenders/presentation/viewmodel/tenders_view_model.dart';

class AdminTenderAwardScreen extends ConsumerStatefulWidget {
  final String tenderId;
  const AdminTenderAwardScreen({super.key, required this.tenderId});

  @override
  ConsumerState<AdminTenderAwardScreen> createState() =>
      _AdminTenderAwardScreenState();
}

class _AdminTenderAwardScreenState
    extends ConsumerState<AdminTenderAwardScreen> {
  bool participantsLoading = true;
  List<_TenderParticipantMini> participants = const [];
  Tender? tender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTender();
      await _loadParticipants();
      await ref
          .read(tendersViewModelProvider.notifier)
          .loadRanking(widget.tenderId);
    });
  }

  Future<void> _loadTender() async {
    try {
      final item =
          await ref.read(tendersRepositoryProvider).getTenderById(widget.tenderId);
      if (!mounted) return;
      setState(() {
        tender = item;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final res = await Supabase.instance.client
          .from('tender_participants')
          .select('vendor_id,status,eligible')
          .eq('tender_id', widget.tenderId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        participants = (res as List)
            .map((row) => _TenderParticipantMini.fromMap(Map<String, dynamic>.from(row)))
            .toList();
        participantsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        participants = const [];
        participantsLoading = false;
      });
    }
  }

  Future<void> _award() async {
    final currentTender = tender;
    if (currentTender != null) {
      final status = currentTender.status.toLowerCase();
      if (status != 'closed' && status != 'awarded') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This tender cannot be awarded yet because its current status is ${currentTender.status}. Change it to closed first.',
            ),
          ),
        );
        return;
      }

      if (currentTender.submissionDeadline.isAfter(DateTime.now())) {
        final deadline = currentTender.submissionDeadline.toLocal();
        final month = deadline.month.toString().padLeft(2, '0');
        final day = deadline.day.toString().padLeft(2, '0');
        final hour = deadline.hour.toString().padLeft(2, '0');
        final minute = deadline.minute.toString().padLeft(2, '0');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This tender cannot be awarded yet because its submission deadline is still ${deadline.year}-$month-$day $hour:$minute.',
            ),
          ),
        );
        return;
      }
    }

    try {
      final res = await ref
          .read(tendersViewModelProvider.notifier)
          .awardLowest(widget.tenderId);
      final winnerName = (await _loadVendorNames([res.winnerVendorId]))[res.winnerVendorId] ??
          _shortId(res.winnerVendorId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tender awarded to $winnerName with total ${res.winningTotal} EGP.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(tendersViewModelProvider);
    final vendorNamesFuture = _loadVendorNames(st.ranking.map((item) => item.vendorId).toList());
    final approvedParticipants = participants
        .where((item) => item.eligible || item.status.toLowerCase() == 'approved')
        .toList();
    final pendingParticipants = participants
        .where((item) => item.status.toLowerCase() == 'pending')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tender Award Decision'),
        leading: const AppPageBackButton(fallbackRoute: '/admin/tenders'),
        actions: [
          IconButton(
            tooltip: 'Refresh ranking',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadTender();
              await _loadParticipants();
              if (!mounted) return;
              await ref
                  .read(tendersViewModelProvider.notifier)
                  .loadRanking(widget.tenderId);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AwardHero(
            tenderId: widget.tenderId,
            proposalsCount: st.ranking.length,
            participantsCount: participants.length,
            approvedParticipantsCount: approvedParticipants.length,
            tenderStatus: tender?.status ?? '-',
            deadlineLabel: _formatDateTime(tender?.submissionDeadline),
          ),
          const SizedBox(height: 14),
          _AwardActionCard(
            awarding: st.awarding,
            rankingEmpty: st.ranking.isEmpty,
            onAward: _award,
          ),
          const SizedBox(height: 14),
          if (st.rankingLoading)
            const LinearProgressIndicator()
          else if (st.rankingError != null)
            _AwardStateCard(
              icon: Icons.error_outline,
              title: 'Could not load proposal ranking',
              subtitle: st.rankingError!,
              accent: Colors.red,
            )
          else if (st.ranking.isEmpty)
            _AwardStateCard(
              icon: approvedParticipants.isNotEmpty
                  ? Icons.groups_outlined
                  : Icons.inbox_outlined,
              title: approvedParticipants.isNotEmpty
                  ? 'Participants found, but no price offers yet'
                  : 'No submitted proposals yet',
              subtitle: approvedParticipants.isNotEmpty
                  ? 'There ${approvedParticipants.length == 1 ? 'is' : 'are'} ${approvedParticipants.length} approved participant${approvedParticipants.length == 1 ? '' : 's'} in this tender, but no vendor has submitted a lowest price offer yet. Pending requests: $pendingParticipants.'
                  : 'The lowest-offer ranking will appear here after vendors submit proposals.',
            )
          else ...[
            FutureBuilder<Map<String, String>>(
              future: vendorNamesFuture,
              builder: (context, snapshot) {
                final names = snapshot.data ?? const <String, String>{};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Lowest to Highest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ...st.ranking.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProposalRankCard(
                          rank: item.rank,
                          vendorName: names[item.vendorId] ?? _shortId(item.vendorId),
                          totalLabel: '${item.financialTotal} EGP',
                          submittedAt: item.submittedAt.toLocal().toString(),
                          highlight: item.rank == 1,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          if (st.awardError != null) ...[
            const SizedBox(height: 14),
            _AwardStateCard(
              icon: Icons.warning_amber_outlined,
              title: 'Award could not be completed',
              subtitle: st.awardError!,
              accent: const Color(0xFFB3261E),
            ),
          ],
          if (st.awardResult != null) ...[
            const SizedBox(height: 14),
            FutureBuilder<Map<String, String>>(
              future: _loadVendorNames([st.awardResult!.winnerVendorId]),
              builder: (context, snapshot) {
                final winnerName =
                    snapshot.data?[st.awardResult!.winnerVendorId] ??
                        _shortId(st.awardResult!.winnerVendorId);
                return _AwardSuccessCard(
                  tenderId: widget.tenderId,
                  winnerVendorName: winnerName,
                  winningTotal: '${st.awardResult!.winningTotal} EGP',
                  proposalId: st.awardResult!.proposalId,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, String>> _loadVendorNames(List<String> ids) async {
    final uniqueIds = ids.toSet().toList();
    if (uniqueIds.isEmpty) return const {};

    final res = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .inFilter('id', uniqueIds);

    final map = <String, String>{};
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

  static String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _AwardHero extends StatelessWidget {
  final String tenderId;
  final int proposalsCount;
  final int participantsCount;
  final int approvedParticipantsCount;
  final String tenderStatus;
  final String deadlineLabel;

  const _AwardHero({
    required this.tenderId,
    required this.proposalsCount,
    required this.participantsCount,
    required this.approvedParticipantsCount,
    required this.tenderStatus,
    required this.deadlineLabel,
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
            'Award Workflow',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Finalize the lowest compliant proposal',
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
          const SizedBox(height: 8),
          Text(
            'Status: $tenderStatus | Deadline: $deadlineLabel',
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
              _HeroMetric(
                label: 'Ranked Proposals',
                value: '$proposalsCount',
              ),
              _HeroMetric(
                label: 'Participants',
                value: '$participantsCount',
              ),
              _HeroMetric(
                label: 'Approved',
                value: '$approvedParticipantsCount',
              ),
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

class _AwardActionCard extends StatelessWidget {
  final bool awarding;
  final bool rankingEmpty;
  final VoidCallback onAward;

  const _AwardActionCard({
    required this.awarding,
    required this.rankingEmpty,
    required this.onAward,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Award Recommendation',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you confirm this action, the tender will be awarded to the current lowest ranked proposal returned by the system.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: awarding || rankingEmpty ? null : onAward,
                icon: awarding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text('Award Lowest Proposal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalRankCard extends StatelessWidget {
  final int rank;
  final String vendorName;
  final String totalLabel;
  final String submittedAt;
  final bool highlight;

  const _ProposalRankCard({
    required this.rank,
    required this.vendorName,
    required this.totalLabel,
    required this.submittedAt,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = highlight
        ? const Color(0xFFF0F7ED)
        : cs.surfaceContainerHighest;
    final rankColor = highlight ? const Color(0xFF0B6E4F) : cs.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendorName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total: $totalLabel',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: $submittedAt',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (highlight)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6E4F).withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Lowest',
                  style: TextStyle(
                    color: Color(0xFF0B6E4F),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AwardSuccessCard extends StatelessWidget {
  final String tenderId;
  final String winnerVendorName;
  final String winningTotal;
  final String proposalId;

  const _AwardSuccessCard({
    required this.tenderId,
    required this.winnerVendorName,
    required this.winningTotal,
    required this.proposalId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0F7ED),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFF0B6E4F)),
                SizedBox(width: 8),
                Text(
                  'Award Completed',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0B6E4F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Winner: $winnerVendorName'),
            const SizedBox(height: 4),
            Text('Winning total: $winningTotal'),
            const SizedBox(height: 4),
            Text('Proposal ID: $proposalId'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/admin/tenders/$tenderId/payment'),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Go to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AwardStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _AwardStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
          ],
        ),
      ),
    );
  }
}

class _TenderParticipantMini {
  final String vendorId;
  final String status;
  final bool eligible;

  const _TenderParticipantMini({
    required this.vendorId,
    required this.status,
    required this.eligible,
  });

  factory _TenderParticipantMini.fromMap(Map<String, dynamic> map) {
    return _TenderParticipantMini(
      vendorId: (map['vendor_id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      eligible: (map['eligible'] ?? false) == true,
    );
  }
}
