import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tenders/data/models/tender.dart';
import '../../../tenders/presentation/viewmodel/tenders_view_model.dart';
import 'tender_award/tender_award_models.dart';
import 'tender_award/tender_award_widgets.dart';

class AdminTenderAwardScreen extends ConsumerStatefulWidget {
  final String tenderId;

  const AdminTenderAwardScreen({super.key, required this.tenderId});

  @override
  ConsumerState<AdminTenderAwardScreen> createState() =>
      _AdminTenderAwardScreenState();
}

class _AdminTenderAwardScreenState
    extends ConsumerState<AdminTenderAwardScreen> {
  List<TenderParticipantMini> participants = const [];
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
            .map(
              (row) =>
                  TenderParticipantMini.fromMap(Map<String, dynamic>.from(row)),
            )
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        participants = const [];
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
      final winnerName =
          (await _loadVendorNames([res.winnerVendorId]))[res.winnerVendorId] ??
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
    final vendorNamesFuture = _loadVendorNames(
      st.ranking.map((item) => item.vendorId).toList(),
    );
    final approvedParticipants = participants
        .where(
          (item) => item.eligible || item.status.toLowerCase() == 'approved',
        )
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
          AdminTenderAwardHero(
            tenderId: widget.tenderId,
            proposalsCount: st.ranking.length,
            participantsCount: participants.length,
            approvedParticipantsCount: approvedParticipants.length,
            tenderStatus: tender?.status ?? '-',
            deadlineLabel: _formatDateTime(tender?.submissionDeadline),
          ),
          const SizedBox(height: 14),
          AdminTenderAwardActionCard(
            awarding: st.awarding,
            rankingEmpty: st.ranking.isEmpty,
            onAward: _award,
          ),
          const SizedBox(height: 14),
          if (st.rankingLoading)
            const LinearProgressIndicator()
          else if (st.rankingError != null)
            AdminTenderAwardStateCard(
              icon: Icons.error_outline,
              title: 'Could not load proposal ranking',
              subtitle: st.rankingError!,
              accent: Colors.red,
            )
          else if (st.ranking.isEmpty)
            AdminTenderAwardStateCard(
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
                        child: ProposalRankCard(
                          rank: item.rank,
                          vendorName:
                              names[item.vendorId] ?? _shortId(item.vendorId),
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
            AdminTenderAwardStateCard(
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
                return AdminTenderAwardSuccessCard(
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
