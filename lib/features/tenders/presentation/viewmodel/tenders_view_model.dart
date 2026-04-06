import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/tenders_repository_impl.dart';
import '../../domain/repositories/tenders_repository.dart';
import '../../data/sources/tenders_remote_data_source.dart';
import '../../data/models/tender_award_result.dart';
import '../../data/models/tender_ranking_row.dart';
import 'tenders_state.dart';

final tendersRepositoryProvider = Provider<TendersRepository>((ref) {
  final remote = TendersRemoteDataSourceImpl(Supabase.instance.client);
  return TendersRepositoryImpl(remote);
});

final tendersViewModelProvider =
    StateNotifierProvider<TendersViewModel, TendersState>((ref) {
  final repo = ref.watch(tendersRepositoryProvider);
  return TendersViewModel(repo);
});

class TendersViewModel extends StateNotifier<TendersState> {
  final TendersRepository repo;
  TendersViewModel(this.repo) : super(const TendersState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await repo.getTenders();
      state = state.copyWith(loading: false, items: items);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// ✅ Lowest → highest ranking
  Future<List<TenderRankingRow>> loadRanking(String tenderId) async {
    // reset ranking state
    state = state.copyWith(
      rankingLoading: true,
      rankingError: null,
      ranking: const [],
    );

    try {
      final rows = await repo.getTenderRanking(tenderId);
      state = state.copyWith(rankingLoading: false, ranking: rows);
      return rows;
    } catch (e) {
      state = state.copyWith(
        rankingLoading: false,
        rankingError: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// ✅ Admin award to lowest
  Future<TenderAwardResult> awardLowest(String tenderId) async {
    state = state.copyWith(
      awarding: true,
      awardError: null,
      awardResult: null,
    );

    try {
      final res = await repo.finalizeTenderAward(tenderId);
      state = state.copyWith(awarding: false, awardResult: res);
      return res;
    } catch (e) {
      state = state.copyWith(
        awarding: false,
        awardError: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}