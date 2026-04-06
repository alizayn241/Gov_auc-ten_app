import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';

  final FlutterSecureStorage _secure;
  TokenStorage(this._secure);

  Future<void> saveToken(String token) => _secure.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _secure.read(key: _tokenKey);
  Future<void> deleteToken() => _secure.delete(key: _tokenKey);

  Future<void> saveRole(String role) => _secure.write(key: _roleKey, value: role);
  Future<String?> readRole() => _secure.read(key: _roleKey);
  Future<void> deleteRole() => _secure.delete(key: _roleKey);
}
