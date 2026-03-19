import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../data/models/auth_form_data.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> login() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return false;
    }

    _setLoading(true);
    try {
      await _authService.login(
        AuthFormData(
          email: emailController.text.trim(),
          password: passwordController.text,
        ),
      );
      return true;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
