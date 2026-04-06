import '../models/user.dart';
import '../sources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remote,
    required this.tokenStorage,
  });

  @override
  Future<User> login(String email, String password) async {
    final user = await remote.login(email, password);
    if (user.token != null) {
      await tokenStorage.saveToken(user.token!);
    }
    await tokenStorage.saveRole(user.role);
    return user;
  }

  @override
  Future<User> signup({
    required String name,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    final user = await remote.signup(
      name: name,
      nationalId: nationalId,
      email: email,
      phone: phone,
      password: password,
    );
    return user;
  }

  @override
  Future<void> logout() async {
    await remote.logout();
    await tokenStorage.deleteToken();
    await tokenStorage.deleteRole();
  }

  @override
  Future<String?> getSavedToken() async {
    return await tokenStorage.readToken();
  }

  @override
  Future<String?> getSavedRole() async {
    return await tokenStorage.readRole();
  }

  @override
  Future<User?> getCurrentUserWithRole() async {
    return await remote.getCurrentUser();
  }
}
