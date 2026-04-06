const _unset = Object();

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isInitialized;
  final bool hasSeenOnboarding;
  final String? role;
  final String? error;
  final String? userId;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isInitialized = false,
    this.hasSeenOnboarding = false,
    this.role,
    this.error,
    this.userId,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isInitialized,
    bool? hasSeenOnboarding,
    Object? role = _unset,
    Object? error = _unset,
    Object? userId = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      role: identical(role, _unset) ? this.role : role as String?,
      error: identical(error, _unset) ? this.error : error as String?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
    );
  }

  bool get isAdmin => (role ?? '').toLowerCase() == 'admin';
  bool get isStaff => (role ?? '').toLowerCase() == 'staff';
  bool get isCitizen => (role ?? '').toLowerCase() == 'citizen';
}
