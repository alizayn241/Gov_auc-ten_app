import '../../data/models/tender.dart';
import '../../data/models/tender_participation.dart';

class TenderDetailsState {
  final bool loading;
  final bool applying;
  final String? error;
  final Tender? tender;
  final TenderParticipation? participation;

  const TenderDetailsState({
    this.loading = false,
    this.applying = false,
    this.error,
    this.tender,
    this.participation,
  });

  TenderDetailsState copyWith({
    bool? loading,
    bool? applying,
    String? error,
    Tender? tender,
    TenderParticipation? participation,
  }) {
    return TenderDetailsState(
      loading: loading ?? this.loading,
      applying: applying ?? this.applying,
      error: error,
      tender: tender ?? this.tender,
      participation: participation ?? this.participation,
    );
  }
}
