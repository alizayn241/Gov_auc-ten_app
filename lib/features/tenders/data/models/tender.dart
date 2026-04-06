class Tender {
  final String id;
  final String title;
  final String? referenceNo;
  final String? entity;
  final String status;
  final DateTime submissionDeadline;

  Tender({
    required this.id,
    required this.title,
    required this.referenceNo,
    required this.entity,
    required this.status,
    required this.submissionDeadline,
  });

  factory Tender.fromJson(Map<String, dynamic> json) {
    return Tender(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      referenceNo: json['reference_no']?.toString(),
      entity: json['entity']?.toString(),
      status: (json['status'] ?? 'draft').toString(),
      submissionDeadline: DateTime.parse(json['submission_deadline'].toString()),
    );
  }
}