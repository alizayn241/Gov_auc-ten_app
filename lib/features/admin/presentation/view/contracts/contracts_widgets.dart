import 'package:flutter/material.dart';

import 'contracts_models.dart';

class ContractCard extends StatelessWidget {
  final ContractRow contract;

  const ContractCard({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contract #${contract.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _ContractStatusChip(text: contract.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tender: ${contract.tenderId}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            Text(
              'Vendor: ${contract.vendorId}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              'Value: ${contract.contractValue}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Created: ${contract.createdAtLabel}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractStatusChip extends StatelessWidget {
  final String text;

  const _ContractStatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
