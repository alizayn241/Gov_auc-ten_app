class Validators {
  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final emptyError = requiredField(value, fieldName: 'Email');
    if (emptyError != null) {
      return emptyError;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? nationalId(String? value) {
    final emptyError = requiredField(value, fieldName: 'National ID');
    if (emptyError != null) {
      return emptyError;
    }

    if (value!.trim().length < 10) {
      return 'Invalid ID length';
    }
    return null;
  }

  static String? phone(String? value) {
    return requiredField(value, fieldName: 'Phone');
  }

  static String? password(String? value) {
    final emptyError = requiredField(value, fieldName: 'Password');
    if (emptyError != null) {
      return emptyError;
    }

    if (value!.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? strongPassword(String? value) {
    final emptyError = requiredField(value, fieldName: 'Password');
    if (emptyError != null) {
      return emptyError;
    }

    final trimmed = value!.trim();
    if (trimmed.length < 8) {
      return 'Minimum 8 characters';
    }
    if (!RegExp(r'\d').hasMatch(trimmed)) {
      return 'Include at least 1 number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final emptyError = requiredField(
      value,
      fieldName: 'Confirm password',
    );
    if (emptyError != null) {
      return emptyError;
    }

    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  const Validators._();
}
