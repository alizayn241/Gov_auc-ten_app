class RecentActivityItem {
  final DateTime sortAt;
  final String title;
  final String subtitle;
  final RecentActivityType type;

  const RecentActivityItem({
    required this.sortAt,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

enum RecentActivityType { user, approval, payment, cancellation }

List<Map<String, dynamic>> asRows(dynamic value) {
  if (value is List) {
    return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return const [];
}

DateTime? parseActivityDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

double toActivityDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String displayActivityName(Map<String, dynamic> row) {
  final name = (row['display_name'] ?? '').toString().trim();
  if (name.isNotEmpty) return name;
  final id = (row['id'] ?? '').toString();
  return id.length <= 8 ? id : id.substring(0, 8);
}

String titleCaseActivity(String text) {
  if (text.isEmpty) return text;
  return text
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String formatActivityDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd $hh:$min';
}
