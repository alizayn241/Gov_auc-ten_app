import '../repositories/auth_repository.dart';

class GetSavedTokenUseCase {
  final AuthRepository repo;
  GetSavedTokenUseCase(this.repo);

  Future<String?> call() => repo.getSavedToken();
}
