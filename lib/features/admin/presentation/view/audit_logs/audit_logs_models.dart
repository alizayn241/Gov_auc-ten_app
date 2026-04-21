class AuditLogItem {
  final String level;
  final String title;
  final String subtitle;
  final String time;

  const AuditLogItem(this.level, this.title, this.subtitle, this.time);
}

List<AuditLogItem> mockAuditLogs() => const [
  AuditLogItem(
    'Info',
    'User created',
    'Admin created user #401',
    '2026-02-22 10:12',
  ),
  AuditLogItem(
    'Warning',
    'Failed login attempts',
    '5 attempts from IP 192.168.1.10',
    '2026-02-22 09:40',
  ),
  AuditLogItem(
    'Critical',
    'Role escalation blocked',
    'Attempt to assign admin role denied',
    '2026-02-21 22:05',
  ),
  AuditLogItem(
    'Info',
    'Process updated',
    'Staff edited process #112',
    '2026-02-21 18:15',
  ),
];
