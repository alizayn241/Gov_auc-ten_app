import 'package:flutter/material.dart';

import 'audit_logs_models.dart';

class AuditLogsFilterBar extends StatelessWidget {
  final String level;
  final ValueChanged<String> onChanged;

  const AuditLogsFilterBar({
    super.key,
    required this.level,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.filter_list),
        const SizedBox(width: 8),
        const Text('Level:'),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: level,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'Info', child: Text('Info')),
            DropdownMenuItem(value: 'Warning', child: Text('Warning')),
            DropdownMenuItem(value: 'Critical', child: Text('Critical')),
          ],
          onChanged: (value) => onChanged(value ?? 'All'),
        ),
      ],
    );
  }
}

class AuditLogTile extends StatelessWidget {
  final AuditLogItem log;

  const AuditLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (log.level.toLowerCase()) {
      case 'critical':
        icon = Icons.report_gmailerrorred_outlined;
        break;
      case 'warning':
        icon = Icons.warning_amber_outlined;
        break;
      case 'info':
      default:
        icon = Icons.info_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(
            log.title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${log.subtitle}\n${log.time}',
            style: const TextStyle(height: 1.25),
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Open log details (demo)')),
          ),
        ),
      ),
    );
  }
}
