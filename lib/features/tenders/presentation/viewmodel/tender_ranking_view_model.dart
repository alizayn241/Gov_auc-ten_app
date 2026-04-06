import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/tenders_repository.dart';
import 'tenders_view_model.dart';
import 'tender_ranking_state.dart';

final tenderRankingViewModelProvider = StateNotifierProvider.family<
    TenderRankingViewModel, TenderRankingState, String>((ref, tenderId) {
  final repo = ref.watch(tendersRepositoryProvider);
  return TenderRankingViewModel(repo: repo, tenderId: tenderId);
});

class TenderRankingViewModel extends StateNotifier<TenderRankingState> {
  final TendersRepository repo;
  final String tenderId;

  TenderRankingViewModel({
    required this.repo,
    required this.tenderId,
  }) : super(const TenderRankingState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await repo.getTenderRanking(tenderId);
      state = state.copyWith(loading: false, items: items);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}