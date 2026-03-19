import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../data/models/auth_form_data.dart';

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> signup() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return false;
    }

    _setLoading(true);
    try {
      await _authService.signup(
        AuthFormData(
          name: nameController.text.trim(),
          nationalId: nationalIdController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
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
    nameController.dispose();
    nationalIdController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
