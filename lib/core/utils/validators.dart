class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
    }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    // Strong-ish: 8+ chars, upper, lower, number
    final ok = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(v);
    return ok ? null : 'Min 8 chars with upper, lower, number';
  }

  static String? nationalId(String? v) {
    if (v == null || v.trim().isEmpty) return 'National ID is required';
    final digits = RegExp(r'^\d{10,14}$').hasMatch(v.trim());
    return digits ? null : 'National ID should be 10–14 digits';
  }

  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }
}
