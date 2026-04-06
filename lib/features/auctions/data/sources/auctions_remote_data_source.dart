import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_auction_participant.dart';
import '../models/admin_invoice_item.dart';
import '../models/auction_document_item.dart';

class AuctionsAdminRemoteDataSource {
  final SupabaseClient sb;
  AuctionsAdminRemoteDataSource(this.sb);

  Future<String> createAuction({
    required String title,
    required String category,
    required num startPrice,
    required DateTime startDate,
    required DateTime endTime,
  }) async {
    final res = await sb.rpc('create_auction', params: {
      'p_title': title,
      'p_category': category,
      'p_start_price': startPrice,
      'p_start_date': startDate.toIso8601String(),
      'p_end_time': endTime.toIso8601String(),
    });

    if (res == null) {
      throw Exception('create_auction returned null');
    }

    if (res is String) return res;
    if (res is Map && res['id'] != null) return res['id'].toString();

    return res.toString();
  }

  Future<void> updateAuction({
    required String auctionId,
    required String title,
    required String category,
    required num startPrice,
    required DateTime startDate,
    required DateTime endTime,
  }) async {
    await sb.rpc('update_auction', params: {
      'p_auction_id': auctionId,
      'p_title': title,
      'p_category': category,
      'p_start_price': startPrice,
      'p_start_date': startDate.toIso8601String(),
      'p_end_time': endTime.toIso8601String(),
    });
  }

  Future<void> publishAuction(String auctionId) async {
    await sb.rpc('set_auction_status', params: {
      'p_auction_id': auctionId,
      'p_status': 'published',
    });
  }

  Future<void> setAuctionStatus({
    required String auctionId,
    required String status,
  }) async {
    await sb.rpc('set_auction_status', params: {
      'p_auction_id': auctionId,
      'p_status': status,
    });
  }

  Future<List<AuctionDocumentItem>> getDocuments(String auctionId) async {
    final res = await sb
        .from('auction_documents')
        .select('*')
        .eq('auction_id', auctionId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => AuctionDocumentItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addDocument({
    required String auctionId,
    required String path,
    required String docType,
    required String visibility,
  }) async {
    await sb.from('auction_documents').insert({
      'auction_id': auctionId,
      'path': path,
      'doc_type': docType,
      'visibility': visibility,
      'created_by': sb.auth.currentUser?.id,
    });
  }

  Future<List<AdminAuctionParticipant>> getParticipants(String auctionId) async {
    final res = await sb
        .from('auction_participants')
        .select('user_id,status,eligible,reviewed_at,created_at')
        .eq('auction_id', auctionId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => AdminAuctionParticipant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> reviewParticipant({
    required String auctionId,
    required String userId,
    required String status,
    String? reason,
    String? notes,
  }) async {
    await sb.rpc('review_participant', params: {
      'p_auction_id': auctionId,
      'p_user_id': userId,
      'p_status': status,
      'p_reason': reason,
      'p_notes': notes,
    });
  }

  Future<Map<String, dynamic>> finalizeAuction(String auctionId) async {
    final res = await sb.rpc('finalize_auction', params: {
      'p_auction_id': auctionId,
    });

    if (res == null) {
      throw Exception('finalize_auction returned null');
    }

    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }

    if (res is String) {
      final decoded = jsonDecode(res);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw Exception('Unexpected finalize_auction response type: ${res.runtimeType}');
  }

  Future<AdminInvoiceItem?> getInvoiceByAuction(String auctionId) async {
    final res = await sb
        .from('invoices')
        .select('*')
        .eq('auction_id', auctionId)
        .maybeSingle();

    if (res == null) return null;
    return AdminInvoiceItem.fromJson(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String invoiceId,
    required num amount,
    required String method,
    required String reference,
  }) async {
    final res = await sb.rpc('confirm_payment', params: {
      'p_invoice_id': invoiceId,
      'p_amount': amount,
      'p_method': method,
      'p_reference': reference,
    });

    if (res == null) {
      throw Exception('confirm_payment returned null');
    }

    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }

    if (res is String) {
      final decoded = jsonDecode(res);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw Exception('Unexpected confirm_payment response type: ${res.runtimeType}');
  }
}