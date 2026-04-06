import '../../data/models/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repo;
  LoginUseCase(this.repo);

  Future<User> call(String email, String password) => repo.login(email, password);
}
