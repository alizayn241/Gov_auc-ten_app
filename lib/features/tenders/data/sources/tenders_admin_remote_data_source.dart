import 'package:supabase_flutter/supabase_flutter.dart';

class TendersAdminRemoteDataSource {
  final SupabaseClient sb;
  TendersAdminRemoteDataSource(this.sb);

  Future<Map<String, dynamic>> getTenderById(String tenderId) async {
    final res = await sb
        .from('tenders')
        .select(
          'id,title,reference_no,entity,status,submission_deadline,opening_date,created_by',
        )
        .eq('id', tenderId)
        .single();

    return Map<String, dynamic>.from(res);
  }

  Future<String> createTender({
    required String title,
    String? referenceNo,
    String? entity,
    required DateTime submissionDeadline,
    DateTime? openingDate,
    String status = 'open',
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'reference_no':
          referenceNo == null || referenceNo.trim().isEmpty ? null : referenceNo.trim(),
      'entity': entity == null || entity.trim().isEmpty ? null : entity.trim(),
      'status': status,
      'submission_deadline': submissionDeadline.toIso8601String(),
      'opening_date': openingDate?.toIso8601String(),
      'created_by': sb.auth.currentUser?.id,
    };

    final res = await sb.from('tenders').insert(payload).select('id').single();
    final id = res['id'];

    if (id == null) {
      throw Exception('Failed to create tender');
    }

    return id.toString();
  }

  Future<void> updateTender({
    required String tenderId,
    required String title,
    String? referenceNo,
    String? entity,
    required DateTime submissionDeadline,
    DateTime? openingDate,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'reference_no':
          referenceNo == null || referenceNo.trim().isEmpty ? null : referenceNo.trim(),
      'entity': entity == null || entity.trim().isEmpty ? null : entity.trim(),
      'status': status,
      'submission_deadline': submissionDeadline.toIso8601String(),
      'opening_date': openingDate?.toIso8601String(),
    };

    await sb.from('tenders').update(payload).eq('id', tenderId);
  }

  Future<void> updateTenderStatus({
    required String tenderId,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
    };

    if (status.toLowerCase() == 'closed') {
      payload['submission_deadline'] = DateTime.now().toIso8601String();
    }

    await sb.from('tenders').update(payload).eq('id', tenderId);
  }

  Future<void> deleteTender(String tenderId) async {
    await sb.from('tenders').delete().eq('id', tenderId);
  }
}
