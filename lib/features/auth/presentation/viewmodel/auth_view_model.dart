import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/prefs_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/sources/auth_mock_api.dart';
import '../../data/sources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_saved_token_usecase.dart';
import 'auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(_secureStorageProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = AuthRemoteDataSourceImpl(Supabase.instance.client);

  return AuthRepositoryImpl(
    remote: remote,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthViewModel(
    getSavedToken: GetSavedTokenUseCase(repo),
    login: LoginUseCase(repo),
    signup: SignupUseCase(repo),
    logout: LogoutUseCase(repo),
    repo: repo,
  );
});

class AuthViewModel extends StateNotifier<AuthState> {
  final GetSavedTokenUseCase getSavedToken;
  final LoginUseCase login;
  final SignupUseCase signup;
  final LogoutUseCase logout;
  final AuthRepository repo;

  final _controller = StreamController<AuthState>.broadcast();
  @override
  Stream<AuthState> get stream => _controller.stream;

  AuthViewModel({
    required this.getSavedToken,
    required this.login,
    required this.signup,
    required this.logout,
    required this.repo,
  }) : super(const AuthState());

  void _emitRefresh() => _controller.add(state);

Future<void> bootstrap() async {
  try {
    final user = await repo.getCurrentUserWithRole();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = PrefsStorage(prefs).hasSeenOnboarding;

    state = state.copyWith(
      isAuthenticated: user != null,
      role: user?.role,
      error: null,
      isInitialized: true,
      hasSeenOnboarding: hasSeenOnboarding,
      userId: userId,
    );
  } catch (_) {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = PrefsStorage(prefs).hasSeenOnboarding;
    state = state.copyWith(
      isAuthenticated: false,
      role: null,
      error: null,
      isInitialized: true,
      hasSeenOnboarding: hasSeenOnboarding,
      userId: null,
    );
  }
  _emitRefresh();
}
Future<void> doLogin({
  required String email,
  required String password,
}) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    final user = await login(email, password);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      role: user.role,
      error: null,
      userId: userId,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString().replaceFirst('Exception: ', ''),
    );
    rethrow;
  } finally {
    _emitRefresh();
  }
}


  Future<bool> doSignup({
    required String name,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    _emitRefresh();

    try {
      final user = await signup(
        name: name,
        nationalId: nationalId,
        email: email,
        phone: phone,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        role: null,
        error: null,
        userId: null,
      );
      _emitRefresh();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      _emitRefresh();
      return false;
    }
  }

Future<void> doLogout() async {
  state = state.copyWith(isLoading: true, error: null);
  _emitRefresh();

  await logout();

  state = state.copyWith(
    isLoading: false,
    isAuthenticated: false,
    role: null,
    error: null,
    userId: null,
  );
  _emitRefresh();
}

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await PrefsStorage(prefs).setHasSeenOnboarding(true);
    state = state.copyWith(hasSeenOnboarding: true);
    _emitRefresh();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
