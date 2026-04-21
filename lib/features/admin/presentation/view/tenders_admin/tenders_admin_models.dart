class TenderAdminItem {
  final String id;
  final String title;
  final String referenceNo;
  final String entity;
  final String status;
  final DateTime? submissionDeadline;
  final DateTime? createdAt;

  const TenderAdminItem({
    required this.id,
    required this.title,
    required this.referenceNo,
    required this.entity,
    required this.status,
    required this.submissionDeadline,
    required this.createdAt,
  });

  factory TenderAdminItem.fromMap(Map<String, dynamic> map) {
    return TenderAdminItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      referenceNo: (map['reference_no'] ?? '').toString(),
      entity: (map['entity'] ?? 'Government').toString(),
      status: (map['status'] ?? 'draft').toString(),
      submissionDeadline: DateTime.tryParse(
        (map['submission_deadline'] ?? '').toString(),
      )?.toLocal(),
      createdAt: DateTime.tryParse(
        (map['created_at'] ?? '').toString(),
      )?.toLocal(),
    );
  }

  String get deadlineLabel {
    final value = submissionDeadline;
    if (value == null) return '-';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}

class TenderMetrics {
  final int openLike;
  final int awarded;

  const TenderMetrics({
    required this.openLike,
    required this.awarded,
  });

  factory TenderMetrics.fromItems(List<TenderAdminItem> items) {
    var openLike = 0;
    var awarded = 0;

    for (final item in items) {
      final status = item.status.toLowerCase();
      if (status == 'published' || status == 'open' || status == 'evaluating') {
        openLike++;
      }
      if (status == 'awarded') {
        awarded++;
      }
    }

    return TenderMetrics(
      openLike: openLike,
      awarded: awarded,
    );
  }
}
