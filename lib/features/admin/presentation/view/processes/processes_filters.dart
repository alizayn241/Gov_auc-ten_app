import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

class ProcessesFilterChips extends StatelessWidget {
  final String type;
  final String lifecycle;
  final String creator;
  final ValueChanged<String> onType;
  final ValueChanged<String> onLifecycle;
  final ValueChanged<String> onCreator;

  const ProcessesFilterChips({
    super.key,
    required this.type,
    required this.lifecycle,
    required this.creator,
    required this.onType,
    required this.onLifecycle,
    required this.onCreator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          label: context.tr('Type', 'النوع'),
          options: const ['All', 'Auction', 'Tender'],
          selected: type,
          onSelect: onType,
        ),
        const SizedBox(height: 7),
        _ChipRow(
          label: context.tr('View', 'عرض'),
          options: const ['Active', 'Completed', 'All'],
          selected: lifecycle,
          onSelect: onLifecycle,
        ),
        const SizedBox(height: 7),
        _ChipRow(
          label: context.tr('Creator', 'المنشئ'),
          options: const ['All', 'Staff only'],
          selected: creator,
          onSelect: onCreator,
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.45),
          ),
        ),
        const SizedBox(width: 8),
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: selected == option
                      ? cs.primaryContainer
                      : cs.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: selected == option
                        ? cs.primary.withOpacity(0.5)
                        : cs.outline.withOpacity(0.2),
                    width: selected == option ? 1 : 0.5,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected == option
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
