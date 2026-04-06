import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/app_notifications_service.dart';
import '../../../auth/presentation/viewmodel/auth_view_model.dart';

final notificationsServiceProvider = Provider<AppNotificationsService>((ref) {
  return AppNotificationsService(Supabase.instance.client);
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final auth = ref.watch(authViewModelProvider);
  if (!auth.isAuthenticated) return 0;

  final service = ref.watch(notificationsServiceProvider);
  final rows = await service.listNotificationsForCurrentUser();
  return rows.where((row) => row['read_at'] == null).length;
});
