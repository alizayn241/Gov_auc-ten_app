import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/tenders_repository.dart';
import 'tenders_view_model.dart';
import 'tender_details_state.dart';

final tenderDetailsViewModelProvider = StateNotifierProvider.family<
    TenderDetailsViewModel, TenderDetailsState, String>((ref, tenderId) {
  final repo = ref.watch(tendersRepositoryProvider);
  return TenderDetailsViewModel(repo: repo, tenderId: tenderId);
});

class TenderDetailsViewModel extends StateNotifier<TenderDetailsState> {
  final TendersRepository repo;
  final String tenderId;

  TenderDetailsViewModel({
    required this.repo,
    required this.tenderId,
  }) : super(const TenderDetailsState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final t = await repo.getTenderById(tenderId);
      final participation = await repo.getMyParticipation(tenderId);
      state = state.copyWith(
        loading: false,
        tender: t,
        participation: participation,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> applyToTender() async {
    state = state.copyWith(applying: true, error: null);
    try {
      await repo.applyToTender(tenderId);
      final participation = await repo.getMyParticipation(tenderId);
      state = state.copyWith(
        applying: false,
        participation: participation,
      );
    } catch (e) {
      state = state.copyWith(
        applying: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}
