import 'dart:async';
import '../models/user.dart';

class AuthMockApi {
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // ✅ Admin
    if (email.toLowerCase() == 'admin@gov.test' && password == 'Admin1234') {
      return User(
        id: '1',
        name: 'Gov Admin',
        email: email,
        phone: '0000000000',
        nationalId: '1234567890',
        role: 'admin',
        status: 'active',
        token: 'mock_admin_token',
      );
    }

    // ✅ Staff
    if (email.toLowerCase() == 'staff@gov.test' && password == 'Staff1234') {
      return User(
        id: '3',
        name: 'Gov Staff',
        email: email,
        phone: '01111111111',
        nationalId: '11112222333344',
        role: 'staff',
        status: 'active',
        token: 'mock_staff_token',
      );
    }

    // ✅ Citizen (default)
    if (password != 'User1234') {
      throw Exception('Invalid credentials');
    }

    return User(
      id: '2',
      name: 'Citizen User',
      email: email,
      phone: '01000000000',
      nationalId: '9876543210',
      role: 'citizen',
      status: 'active',
      token: 'mock_citizen_token',
    );
  }

  Future<User> signup({
    required String name,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    // ✅ Signup default role = citizen
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      nationalId: nationalId,
      role: 'citizen',
      status: 'active',
      token: 'mock_signup_token',
    );
  }
}
