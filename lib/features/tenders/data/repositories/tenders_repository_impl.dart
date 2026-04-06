import 'package:gov_auction_app/features/tenders/data/models/tender_award_result.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_ranking_row.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_participation.dart';

import '../../domain/repositories/tenders_repository.dart';
import '../models/tender.dart';
import '../sources/tenders_remote_data_source.dart';

class TendersRepositoryImpl implements TendersRepository {
  final TendersRemoteDataSource remote;
  TendersRepositoryImpl(this.remote);

  @override
  Future<List<Tender>> getTenders() => remote.getTenders();

  @override
  Future<Tender> getTenderById(String id) => remote.getTenderById(id);

  @override
  Future<TenderParticipation?> getMyParticipation(String tenderId) {
    return remote.getMyParticipation(tenderId);
  }

  @override
  Future<void> applyToTender(String tenderId) {
    return remote.applyToTender(tenderId);
  }

  @override
  Future<String> submitProposal({
    required String tenderId,
    required num financialTotal,
    String currency = 'EGP',
  }) {
    return remote.submitProposal(
      tenderId: tenderId,
      financialTotal: financialTotal,
      currency: currency,
    );
  }

  @override
  Future<List<TenderRankingRow>> getTenderRanking(String tenderId) {
    return remote.getTenderRanking(tenderId);
  }

  @override
  Future<TenderAwardResult> finalizeTenderAward(String tenderId) {
    return remote.finalizeTenderAward(tenderId);
  }
}
