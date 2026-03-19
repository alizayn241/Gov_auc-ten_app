class AuthFormData {
  final String name;
  final String nationalId;
  final String email;
  final String phone;
  final String password;

  const AuthFormData({
    this.name = '',
    this.nationalId = '',
    required this.email,
    this.phone = '',
    required this.password,
  });
}
