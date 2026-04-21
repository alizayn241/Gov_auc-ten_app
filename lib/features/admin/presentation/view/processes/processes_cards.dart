import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import '../shared/admin_shared.dart';
import 'processes_models.dart';

class ProcessCard extends StatelessWidget {
  final AdminProcessItem process;
  final VoidCallback? onPublish;
  final VoidCallback? onManage;
  final VoidCallback? onOpen;
  final VoidCallback? onParticipants;

  const ProcessCard({
    super.key,
    required this.process,
    this.onPublish,
    this.onManage,
    this.onOpen,
    this.onParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(type: process.type),
                const SizedBox(width: 6),
                _StatusBadge(status: process.statusLabel),
                const Spacer(),
                Text(
                  '#${process.id.length > 8 ? process.id.substring(0, 8) : process.id}',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withOpacity(0.35),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              process.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              process.meta,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.55),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            _CreatorRow(
              label: process.creatorLabel,
              role: process.creatorRole,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (onManage != null)
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    label: context.tr('Manage', 'إدارة'),
                    onTap: onManage!,
                  ),
                if (onOpen != null)
                  _ActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: context.tr('Open', 'فتح'),
                    onTap: onOpen!,
                  ),
                if (onParticipants != null)
                  _ActionButton(
                    icon: Icons.how_to_reg_rounded,
                    label: context.tr('Participants', 'المشاركون'),
                    onTap: onParticipants!,
                  ),
                if (onPublish != null)
                  _ActionButton(
                    icon: Icons.publish_rounded,
                    label: context.tr('Publish', 'نشر'),
                    onTap: onPublish!,
                    filled: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isAuction = type == 'Auction';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isAuction ? const Color(0xFFE3F0FC) : const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isAuction ? const Color(0xFF0C447C) : const Color(0xFF27500A),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    late final Color bg;
    late final Color fg;

    if (lower == 'published' || lower == 'active' || lower == 'live') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (lower == 'draft' || lower == 'pending') {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFF92400E);
    } else if (lower == 'paid' ||
        lower == 'closed' ||
        lower == 'completed' ||
        lower == 'awarded') {
      bg = const Color(0xFFF1EFE8);
      fg = const Color(0xFF5F5E5A);
    } else {
      bg = const Color(0xFFFAECE7);
      fg = const Color(0xFF712B13);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  final String label;
  final String role;

  const _CreatorRow({
    required this.label,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = label.trim().isEmpty
        ? '?'
        : label
            .trim()
            .split(' ')
            .take(2)
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
            .join();

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.isEmpty ? 'Unknown' : label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.65),
          ),
        ),
        if (role.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            '· $role',
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: filled ? cs.primary : cs.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: filled ? Colors.white : cs.onSurface.withOpacity(0.75),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : cs.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
