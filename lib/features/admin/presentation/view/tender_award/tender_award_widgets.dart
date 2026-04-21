import 'package:flutter/material.dart';

class AdminTenderAwardHero extends StatelessWidget {
  final String tenderId;
  final int proposalsCount;
  final int participantsCount;
  final int approvedParticipantsCount;
  final String tenderStatus;
  final String deadlineLabel;

  const AdminTenderAwardHero({
    super.key,
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
              _HeroMetric(label: 'Ranked Proposals', value: '$proposalsCount'),
              _HeroMetric(label: 'Participants', value: '$participantsCount'),
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

class AdminTenderAwardActionCard extends StatelessWidget {
  final bool awarding;
  final bool rankingEmpty;
  final VoidCallback onAward;

  const AdminTenderAwardActionCard({
    super.key,
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

class ProposalRankCard extends StatelessWidget {
  final int rank;
  final String vendorName;
  final String totalLabel;
  final String submittedAt;
  final bool highlight;

  const ProposalRankCard({
    super.key,
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

class AdminTenderAwardSuccessCard extends StatelessWidget {
  final String tenderId;
  final String winnerVendorName;
  final String winningTotal;
  final String proposalId;

  const AdminTenderAwardSuccessCard({
    super.key,
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
                onPressed: null,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Vendor Pays From My Payments'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminTenderAwardStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const AdminTenderAwardStateCard({
    super.key,
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
