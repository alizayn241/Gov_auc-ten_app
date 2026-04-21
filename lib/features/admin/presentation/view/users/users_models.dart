class UserRecord {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String provider;
  final String status;
  final DateTime? createdAt;

  const UserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.provider,
    required this.status,
    required this.createdAt,
  });

  factory UserRecord.fromMap(Map<String, dynamic> map) {
    final resolvedName = _firstNonEmpty([
      map['display_name'],
      map['name'],
      map['full_name'],
      map['username'],
      map['email'],
      map['id'],
    ]);

    return UserRecord(
      id: _firstNonEmpty([map['user_id'], map['id']]),
      name: resolvedName,
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: _normalizeRole((map['role'] ?? 'Citizen').toString()),
      provider: _firstNonEmpty([
        map['provider'],
        map['providers'],
        map['provider_type'],
        'Email',
      ]),
      status: _firstNonEmpty([
        map['status'],
        map['kyc_status'],
        map['auth_status'],
        'unknown',
      ]),
      createdAt: DateTime.tryParse(
        _firstNonEmpty([map['created_at'], map['last_sign_in_at']]),
      )?.toLocal(),
    );
  }

  String get createdLabel {
    final d = createdAt;
    if (d == null) return '-';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _normalizeRole(String value) {
    return switch (value.toLowerCase()) {
      'admin' => 'Admin',
      'staff' => 'Staff',
      _ => 'Citizen',
    };
  }
}
