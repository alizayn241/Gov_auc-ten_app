import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/admin_reports_model.dart';

class AdminReportsState {
  final bool loading;
  final String? error;
  final AdminReportsSummary? data;

  const AdminReportsState({
    this.loading = false,
    this.error,
    this.data,
  });

  AdminReportsState copyWith({
    bool? loading,
    String? error,
    AdminReportsSummary? data,
  }) {
    return AdminReportsState(
      loading: loading ?? this.loading,
      error: error,
      data: data ?? this.data,
    );
  }
}

final adminReportsViewModelProvider =
    StateNotifierProvider<AdminReportsViewModel, AdminReportsState>((ref) {
  return AdminReportsViewModel(Supabase.instance.client);
});

class AdminReportsViewModel extends StateNotifier<AdminReportsState> {
  final SupabaseClient _client;

  AdminReportsViewModel(this._client) : super(const AdminReportsState());

  Future<void> load({required DateTime from, required DateTime to}) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final fromStr = _yyyyMmDd(from);
      final toStr = _yyyyMmDd(to);

      final res = await _client.rpc(
        'get_admin_reports_summary',
        params: {
          'from_date': fromStr,
          'to_date': toStr,
        },
      );

      final map = Map<String, dynamic>.from(res as Map);
      final data = AdminReportsSummary.fromJson(map);

      state = state.copyWith(loading: false, data: data);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static String _yyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}