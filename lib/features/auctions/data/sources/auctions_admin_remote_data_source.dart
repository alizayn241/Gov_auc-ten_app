import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/admin_auction_participant.dart';
import '../models/admin_invoice_item.dart';
import '../models/auction_document_item.dart';

class AuctionsAdminRemoteDataSource {
  final SupabaseClient sb;
  AuctionsAdminRemoteDataSource(this.sb);

  String? _contentTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  String _normalizeStoragePath({
    required String bucket,
    required String path,
  }) {
    final bucketPrefix = '$bucket/';
    if (path.startsWith(bucketPrefix)) {
      return path.substring(bucketPrefix.length);
    }
    return path;
  }

  Future<String> uploadAuctionImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeFileName = fileName.replaceAll(' ', '_');
    final path =
        'auctions/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
    final bucket = AppConstants.auctionImagesBucket;
    final contentType = _contentTypeForFileName(safeFileName);
    late final String uploadedPath;

    try {
      uploadedPath = await sb.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );
    } on StorageException catch (e) {
      if ((e.message).toLowerCase().contains('bucket not found')) {
        throw Exception(
          'Supabase storage bucket "$bucket" was not found. Create a bucket with this exact name in Supabase Storage, or change AppConstants.auctionImagesBucket to your existing bucket name.',
        );
      }
      rethrow;
    }

    final normalizedPath = _normalizeStoragePath(
      bucket: bucket,
      path: uploadedPath,
    );

    return sb.storage.from(bucket).getPublicUrl(normalizedPath);
  }

  Future<String> createAuction({
    required String title,
    required String category,
    required num startPrice,
    required DateTime startDate,
    required DateTime endTime,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
  }) async {
    final res = await sb.rpc('create_auction', params: {
      'p_title': title,
      'p_category': category,
      'p_start_price': startPrice,
      'p_start_date': startDate.toIso8601String(),
      'p_end_time': endTime.toIso8601String(),
      'p_image_url': imageUrl,
    });

    if (res == null) {
      throw Exception('create_auction returned null');
    }

    final auctionId = switch (res) {
      String() => res,
      Map() when res['id'] != null => res['id'].toString(),
      _ => res.toString(),
    };

    final extraFields = <String, dynamic>{};
    if (imageUrl != null && imageUrl.isNotEmpty) {
      extraFields['image_url'] = imageUrl;
    }
    if (location != null && location.trim().isNotEmpty) {
      extraFields['location'] = location.trim();
    }
    if (latitude != null) {
      extraFields['latitude'] = latitude;
    }
    if (longitude != null) {
      extraFields['longitude'] = longitude;
    }

    if (extraFields.isNotEmpty) {
      await sb.from('auctions').update(extraFields).eq('id', auctionId);
    }

    return auctionId;
  }

  Future<void> updateAuction({
    required String auctionId,
    required String title,
    required String category,
    required num startPrice,
    required DateTime startDate,
    required DateTime endTime,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    await sb.rpc('update_auction', params: {
      'p_auction_id': auctionId,
      'p_title': title,
      'p_category': category,
      'p_start_price': startPrice,
      'p_start_date': startDate.toIso8601String(),
      'p_end_time': endTime.toIso8601String(),
    });

    final extraFields = <String, dynamic>{};
    if (location != null) {
      extraFields['location'] = location.trim();
    }
    extraFields['latitude'] = latitude;
    extraFields['longitude'] = longitude;

    await sb.from('auctions').update(extraFields).eq('id', auctionId);
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

    throw Exception(
      'Unexpected finalize_auction response type: ${res.runtimeType}',
    );
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

  Future<AdminInvoiceItem?> getInvoiceByTender(String tenderId) async {
    final res = await sb
        .from('invoices')
        .select('*')
        .eq('tender_id', tenderId)
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

    throw Exception(
      'Unexpected confirm_payment response type: ${res.runtimeType}',
    );
  }
}
