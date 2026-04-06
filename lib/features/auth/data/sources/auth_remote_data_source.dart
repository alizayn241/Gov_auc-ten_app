import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';

abstract class AuthRemoteDataSource {
  Future<User> login(String email, String password);
  Future<User> signup({
    required String name,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
}

/// Supabase implementation of AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl(this._supabase);

  Exception _mapLoginException(Object error) {
    if (error is AuthApiException) {
      final code = error.code?.toLowerCase();
      final message = error.message.toLowerCase();

      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return Exception(
          'The email or password you entered is incorrect. Please try again.',
        );
      }

      if (code == 'email_not_confirmed' ||
          message.contains('email not confirmed')) {
        return Exception(
          'Your email address has not been confirmed yet. Please verify your email and try again.',
        );
      }

      if (code == 'too_many_requests') {
        return Exception(
          'Too many sign-in attempts were made. Please wait a moment and try again.',
        );
      }
    }

    return Exception(
      'We could not sign you in right now. Please try again in a moment.',
    );
  }

  Exception _mapSignupException(Object error) {
    if (error is AuthApiException) {
      final code = error.code?.toLowerCase();
      final message = error.message.toLowerCase();

      if (code == 'user_already_exists' ||
          message.contains('user already registered') ||
          message.contains('already registered') ||
          message.contains('already exists')) {
        return Exception(
          'An account with this email already exists. Please sign in instead.',
        );
      }

      if (code == 'too_many_requests') {
        return Exception(
          'Too many sign-up attempts were made. Please wait a moment and try again.',
        );
      }
    }

    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('duplicate key') || message.contains('already exists')) {
        return Exception(
          'This account already has a saved profile. Please sign in instead.',
        );
      }

      return Exception(
        'Your account could not be completed because the profile record could not be saved. Check the public.profiles table and its RLS policies.',
      );
    }

    return Exception(
      'We could not create your account right now. Please try again in a moment.',
    );
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('We could not sign you in right now. Please try again.');
      }

      // Get user role from profiles table
      final userId = response.user!.id;
      final profileData = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      return User(
        id: response.user!.id,
        email: response.user!.email ?? email,
        name: profileData?['display_name'] ??
            response.user!.userMetadata?['name'] ??
            '',
        phone:
            profileData?['phone'] ?? response.user!.userMetadata?['phone'] ?? '',
        nationalId: profileData?['national_id'] ?? '',
        role: profileData?['role'] ?? 'citizen',
        status: profileData?['kyc_status'] ?? 'pending',
        token: response.session?.accessToken,
      );
    } catch (error) {
      throw _mapLoginException(error);
    }
  }

  @override
  Future<User> signup({
    required String name,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'national_id': nationalId,
        },
      );

      if (response.user == null) {
        throw Exception('We could not create your account right now. Please try again.');
      }

      final userId = response.user!.id;

      // Keep profile creation idempotent in case auth/signup hooks already created it.
      await _supabase.from('profiles').upsert({
        'id': userId,
        'display_name': name,
        'national_id': nationalId,
        'role': 'citizen',
        'account_type': 'individual',
        'kyc_status': 'pending',
      }, onConflict: 'id');

      await _supabase.auth.signOut();

      return User(
        id: userId,
        email: email,
        name: name,
        phone: phone,
        nationalId: nationalId,
        role: 'citizen',
        status: 'pending',
        token: null,
      );
    } catch (error) {
      throw _mapSignupException(error);
    }
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final user = session.user;
    final profileData = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    return User(
      id: user.id,
      email: user.email ?? '',
      name: profileData?['display_name'] ?? user.userMetadata?['name'] ?? '',
      phone: profileData?['phone'] ?? user.userMetadata?['phone'] ?? '',
      nationalId: profileData?['national_id'] ?? '',
      role: profileData?['role'] ?? 'citizen',
      status: profileData?['kyc_status'] ?? 'pending',
      token: session.accessToken,
    );
  }
}
