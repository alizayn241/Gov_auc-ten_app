import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_award_result.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_ranking_row.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_participation.dart';

import '../models/tender.dart';

abstract class TendersRemoteDataSource {
  Future<List<Tender>> getTenders();
  Future<Tender> getTenderById(String id);
  Future<TenderParticipation?> getMyParticipation(String tenderId);
  Future<void> applyToTender(String tenderId);

  /// returns proposal uuid (string)
  Future<String> submitProposal({
    required String tenderId,
    required num financialTotal,
    String currency,
  });

  /// ✅ Admin/Staff: ranking (lowest first)
  Future<List<TenderRankingRow>> getTenderRanking(String tenderId);

  /// ✅ Admin/Staff: award to lowest
  Future<TenderAwardResult> finalizeTenderAward(String tenderId);
}

class TendersRemoteDataSourceImpl implements TendersRemoteDataSource {
  final SupabaseClient sb;
  TendersRemoteDataSourceImpl(this.sb);

  Exception _mapSubmitProposalError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      final code = (error.code ?? '').toLowerCase();

      if (message.contains('not eligible') || code == 'p0001') {
        return Exception(
          'You are not eligible to submit a proposal for this tender yet. Please contact support or wait for your participation to be approved.',
        );
      }

      if (message.contains('deadline')) {
        return Exception(
          'This tender is no longer accepting proposals because the submission deadline has passed.',
        );
      }
    }

    return Exception(
      'We could not submit your proposal right now. Please try again in a moment.',
    );
  }

  Exception _mapFinalizeTenderAwardError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();

      if (message.contains('tender not closed yet')) {
        return Exception(
          'This tender is not ready to be awarded yet. Make sure its status is closed and that the submission deadline has passed, then try again.',
        );
      }

      if (message.contains('no submitted proposals')) {
        return Exception(
          'This tender cannot be awarded yet because no vendor has submitted a proposal.',
        );
      }
    }

    return Exception(
      'We could not complete the tender award right now. Please try again in a moment.',
    );
  }

  @override
  Future<List<Tender>> getTenders() async {
    final rows = await sb
        .from('tenders')
        .select('id,title,reference_no,entity,status,submission_deadline')
        .order('submission_deadline', ascending: true);

    return (rows as List)
        .map((e) => Tender.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Tender> getTenderById(String id) async {
    final row = await sb
        .from('tenders')
        .select('id,title,reference_no,entity,status,submission_deadline')
        .eq('id', id)
        .single();

    return Tender.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<TenderParticipation?> getMyParticipation(String tenderId) async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return null;

    final row = await sb
        .from('tender_participants')
        .select('vendor_id,status,eligible,reviewed_at,created_at')
        .eq('tender_id', tenderId)
        .eq('vendor_id', uid)
        .maybeSingle();

    if (row == null) return null;
    return TenderParticipation.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> applyToTender(String tenderId) async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Please login to participate in this tender');
    }

    final existing = await sb
        .from('tender_participants')
        .select('vendor_id,status')
        .eq('tender_id', tenderId)
        .eq('vendor_id', uid)
        .maybeSingle();

    if (existing != null) {
      throw Exception(
        'Your participation request has already been submitted for this tender.',
      );
    }

    await sb.from('tender_participants').insert({
      'tender_id': tenderId,
      'vendor_id': uid,
      'status': 'pending',
      'eligible': false,
    });
  }

  @override
  Future<String> submitProposal({
    required String tenderId,
    required num financialTotal,
    String currency = 'EGP',
  }) async {
    try {
      final res = await sb.rpc('submit_tender_proposal', params: {
        'p_tender_id': tenderId,
        'p_financial_total': financialTotal,
        'p_currency': currency,
      });

      // RPC should return uuid; Supabase may give String directly.
      if (res == null) {
        throw Exception('We could not submit your proposal right now.');
      }

      if (res is String) return res;
      // sometimes it might come as {"id":"..."} depending on SQL, handle defensively
      if (res is Map && res['id'] != null) return res['id'].toString();

      // last resort
      return res.toString();
    } catch (error) {
      throw _mapSubmitProposalError(error);
    }
  }

  @override
  Future<List<TenderRankingRow>> getTenderRanking(String tenderId) async {
    final res = await sb.rpc('get_tender_ranking', params: {
      'p_tender_id': tenderId,
    });

    if (res == null) return <TenderRankingRow>[];

    // Most common: List<Map<String, dynamic>>
    if (res is List) {
      return res
          .map((e) => TenderRankingRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Sometimes: JSON string
    if (res is String) {
      final decoded = jsonDecode(res);
      if (decoded is List) {
        return decoded
            .map((e) => TenderRankingRow.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    throw Exception('Unexpected get_tender_ranking response type: ${res.runtimeType}');
  }

  @override
  Future<TenderAwardResult> finalizeTenderAward(String tenderId) async {
    try {
      final res = await sb.rpc('finalize_tender_award', params: {
        'p_tender_id': tenderId,
      });

      if (res == null) throw Exception('finalize_tender_award returned null');

      // Most common: Map<String, dynamic>
      if (res is Map) {
        return TenderAwardResult.fromJson(Map<String, dynamic>.from(res));
      }

      // Sometimes: JSON string
      if (res is String) {
        final decoded = jsonDecode(res);
        if (decoded is Map) {
          return TenderAwardResult.fromJson(Map<String, dynamic>.from(decoded));
        }
      }

      throw Exception(
        'Unexpected finalize_tender_award response type: ${res.runtimeType}',
      );
    } catch (error) {
      throw _mapFinalizeTenderAwardError(error);
    }
  }
}
