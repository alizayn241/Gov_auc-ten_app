import '../../data/models/user.dart';
import '../repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository repo;
  SignupUseCase(this.repo);

  Future<User> call({
    required String name,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) {
    return repo.signup(
      name: name,
      nationalId: nationalId,
      email: email,
      phone: phone,
      password: password,
    );
  }
}
