import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  String _level = 'All';

  @override
  Widget build(BuildContext context) {
    final items = _mockLogs().where((l) {
      if (_level == 'All') return true;
      return l.level.toLowerCase() == _level.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              const Text('Level:'),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _level,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Info', child: Text('Info')),
                  DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                ],
                onChanged: (v) => setState(() => _level = v ?? 'All'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((l) => _LogTile(log: l)).toList(),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final _Log log;
  const _LogTile({required this.log});

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
          title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${log.subtitle}\n${log.time}', style: const TextStyle(height: 1.25)),
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

class _Log {
  final String level, title, subtitle, time;
  const _Log(this.level, this.title, this.subtitle, this.time);
}

List<_Log> _mockLogs() => const [
  _Log('Info', 'User created', 'Admin created user #401', '2026-02-22 10:12'),
  _Log('Warning', 'Failed login attempts', '5 attempts from IP 192.168.1.10', '2026-02-22 09:40'),
  _Log('Critical', 'Role escalation blocked', 'Attempt to assign admin role denied', '2026-02-21 22:05'),
  _Log('Info', 'Process updated', 'Staff edited process #112', '2026-02-21 18:15'),
];