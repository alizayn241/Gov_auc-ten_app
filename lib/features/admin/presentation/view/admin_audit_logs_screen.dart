import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';

import 'audit_logs/audit_logs_models.dart';
import 'audit_logs/audit_logs_widgets.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  String _level = 'All';

  @override
  Widget build(BuildContext context) {
    final items = mockAuditLogs().where((log) {
      if (_level == 'All') return true;
      return log.level.toLowerCase() == _level.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AuditLogsFilterBar(
            level: _level,
            onChanged: (value) => setState(() => _level = value),
          ),
          const SizedBox(height: 10),
          ...items.map((log) => AuditLogTile(log: log)),
        ],
      ),
    );
  }
}
