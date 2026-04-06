import '../../data/models/tender.dart';
import '../../data/models/tender_award_result.dart';
import '../../data/models/tender_ranking_row.dart';

class TendersState {
  final bool loading;
  final String? error;
  final List<Tender> items;

  // ✅ Ranking
  final bool rankingLoading;
  final String? rankingError;
  final List<TenderRankingRow> ranking;

  // ✅ Award (Admin)
  final bool awarding;
  final String? awardError;
  final TenderAwardResult? awardResult;

  const TendersState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.rankingLoading = false,
    this.rankingError,
    this.ranking = const [],
    this.awarding = false,
    this.awardError,
    this.awardResult,
  });

  TendersState copyWith({
    bool? loading,
    String? error,
    List<Tender>? items,

    bool? rankingLoading,
    String? rankingError,
    List<TenderRankingRow>? ranking,

    bool? awarding,
    String? awardError,
    TenderAwardResult? awardResult,
  }) {
    return TendersState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,

      rankingLoading: rankingLoading ?? this.rankingLoading,
      rankingError: rankingError,
      ranking: ranking ?? this.ranking,

      awarding: awarding ?? this.awarding,
      awardError: awardError,
      awardResult: awardResult,
    );
  }
}