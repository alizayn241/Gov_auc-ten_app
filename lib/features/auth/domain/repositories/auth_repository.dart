import '../../data/models/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> signup({
    required String name,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> logout();

  Future<String?> getSavedToken();
  Future<String?> getSavedRole();

  Future<User?> getCurrentUserWithRole();
}