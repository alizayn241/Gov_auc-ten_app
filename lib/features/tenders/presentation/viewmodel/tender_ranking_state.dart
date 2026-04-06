import '../../data/models/tender_ranking_row.dart';

class TenderRankingState {
  final bool loading;
  final String? error;
  final List<TenderRankingRow> items;

  const TenderRankingState({
    this.loading = false,
    this.error,
    this.items = const [],
  });

  TenderRankingState copyWith({
    bool? loading,
    String? error,
    List<TenderRankingRow>? items,
  }) {
    return TenderRankingState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
    );
  }
}