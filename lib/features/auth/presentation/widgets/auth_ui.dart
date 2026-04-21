import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';

class AuthHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  const AuthHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Text(
            eyebrow,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 34 : 40,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            color: EntryFlowTokens.textMuted,
            fontSize: compact ? 14 : 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class AuthPanel extends StatelessWidget {
  final Widget child;

  const AuthPanel({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EntryFlowTokens.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: child,
      ),
    );
  }
}

class AuthInfoCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const AuthInfoCard({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF132742),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EntryFlowTokens.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EntryFlowTokens.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: EntryFlowTokens.textMuted,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFieldSpacing extends StatelessWidget {
  final Widget child;

  const AuthFieldSpacing({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }
}
