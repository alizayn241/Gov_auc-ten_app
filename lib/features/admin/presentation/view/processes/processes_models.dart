class AdminProfileMini {
  final String name;
  final String role;

  const AdminProfileMini({
    required this.name,
    required this.role,
  });

  factory AdminProfileMini.fromMap(Map<String, dynamic> map) {
    final name = _firstNonEmpty([
      map['display_name'],
      map['name'],
      map['full_name'],
      map['username'],
      map['id'],
    ]);
    return AdminProfileMini(
      name: name,
      role: (map['role'] ?? 'citizen').toString(),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class AdminProcessItem {
  final String id;
  final String type;
  final String status;
  final String title;
  final String meta;
  final DateTime createdAt;
  final String creatorLabel;
  final String creatorRole;

  const AdminProcessItem({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.meta,
    required this.createdAt,
    required this.creatorLabel,
    required this.creatorRole,
  });

  factory AdminProcessItem.fromAuction(
    Map<String, dynamic> map,
    Map<String, AdminProfileMini> profiles,
  ) {
    final creatorId = (map['created_by'] ?? '').toString();
    final creator = profiles[creatorId];

    return AdminProcessItem(
      id: (map['id'] ?? '').toString(),
      type: 'Auction',
      status: (map['status'] ?? 'draft').toString(),
      title: (map['title'] ?? '').toString(),
      meta: '${map['category'] ?? 'Other'} · '
          'Start: ${_formatDate(map['start_date'])} · '
          'End: ${_formatDate(map['end_time'])} · '
          'Min: EGP ${_toDouble(map['start_price']).toStringAsFixed(0)}',
      createdAt: _parseDate(map['created_at']),
      creatorLabel:
          creator == null || creator.name.isEmpty ? 'Unknown user' : creator.name,
      creatorRole: creator?.role ?? '',
    );
  }

  factory AdminProcessItem.fromTender(Map<String, dynamic> map) {
    return AdminProcessItem(
      id: (map['id'] ?? '').toString(),
      type: 'Tender',
      status: (map['status'] ?? 'draft').toString(),
      title: (map['title'] ?? '').toString(),
      meta: '${map['entity'] ?? 'Government'} · '
          'Deadline: ${_formatDate(map['submission_deadline'])}',
      createdAt: _parseDate(map['created_at']),
      creatorLabel: 'Tender workflow',
      creatorRole: '',
    );
  }

  String get statusLabel => status.isEmpty ? 'draft' : status;

  bool get isCompleted {
    final lower = status.toLowerCase();
    return lower == 'paid' ||
        lower == 'awarded' ||
        lower == 'completed' ||
        lower == 'closed';
  }

  bool get canPublish {
    final lower = status.toLowerCase();
    return lower == 'draft' || lower == 'pending';
  }

  static DateTime _parseDate(dynamic value) {
    return DateTime.tryParse((value ?? '').toString())?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _formatDate(dynamic value) {
    final date = DateTime.tryParse((value ?? '').toString())?.toLocal();
    if (date == null) return '-';

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }
}
