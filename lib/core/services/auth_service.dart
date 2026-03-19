import '../../features/auth/data/models/auth_form_data.dart';

class AuthService {
  Future<void> login(AuthFormData data) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  Future<void> signup(AuthFormData data) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }
}
