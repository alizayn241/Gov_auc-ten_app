import '../../data/models/tender.dart';
import '../../data/models/tender_participation.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_award_result.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_ranking_row.dart';

abstract class TendersRepository {
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

  /// ✅ ranking lowest → highest
  Future<List<TenderRankingRow>> getTenderRanking(String tenderId);

  /// ✅ admin/staff award lowest
  Future<TenderAwardResult> finalizeTenderAward(String tenderId);
}
